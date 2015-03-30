require 'spec_helper'
require 'tempfile'

RSpec.describe Fake::Multitenancy do
  describe "Migrations" do
    it "should add columns for default migrations" do
      class Product < ActiveRecord::Base
        establish_connection adapter: 'sqlite3', database: Tempfile.new('database').path
        connection.create_table table_name do |t|
          t.string :name
        end
      end

      expect(Product.columns.map(&:name)).to eql ['multitenant_id', 'id', 'tenant', 'name']
    end

    it "should not add columns when multitenant: false is passed" do
      class Article < ActiveRecord::Base
        establish_connection adapter: 'sqlite3', database: Tempfile.new('database').path
        connection.create_table table_name, multitenant: false do |t|
          t.string :name
        end
      end

      expect(Article.columns.map(&:name)).to eql ['id', 'name']
    end
  end

  describe "Schema dump" do
    before(:all) do
      class Comment < ActiveRecord::Base
        establish_connection adapter: 'sqlite3', database: Tempfile.new('database').path
        connection.create_table table_name do |t|
          t.text       :content
          t.references :author
        end

        connection.add_index table_name, :author_id
      end

      @schema = ActiveRecord::SchemaDumper.dump(Comment.connection, StringIO.new).string
    end

    it "should create table" do
      expect(@schema).to match(/create_table "comments"/)
    end

    it "should not add primary key" do
      expect(@schema).not_to match(/primary_key/)
      expect(@schema).not_to match(/multitenant_id/)
    end

    it "should not add extra columns" do
      expect(@schema).not_to match(/tenant/)
      expect(@schema).not_to match(/"id"/)
    end

    it "should not add extra indexes" do
      expect(@schema).not_to match(/index_comments_on_tenant/)
      expect(@schema).not_to match(/index_comments_on_id/)
    end
  end

  describe "Multitenancy" do
    before(:all) do
      class Tenant
        def switch
          @@current = self
        end

        attr_accessor :name


        def self.find(name)
          new.tap{ |t| t.name = name }
        end

        def self.current
          @@current
        end
      end
    end

    it "should increment id correctly" do
      class User < ActiveRecord::Base
        establish_connection adapter: 'sqlite3', database: Tempfile.new('database').path
        connection.create_table table_name do |t|
          t.string :login
        end
      end

      Tenant.find('good_old_client').switch

      expect(User.create!.id).to eql(1)
      expect(User.create!.id).to eql(2)
    end

    it "should assign tenant name automaticaly" do
      class Session < ActiveRecord::Base
        establish_connection adapter: 'sqlite3', database: Tempfile.new('database').path
        connection.create_table table_name do |t|
          t.integer :user_id
        end
      end

      Tenant.find('good_old_client').switch

      expect(Session.create!.tenant).to eql 'good_old_client'
    end

    it "should avoid competition situations"

    it "should define default scope for every model" do
      class Message < ActiveRecord::Base
        establish_connection adapter: 'sqlite3', database: Tempfile.new('database').path
        connection.create_table table_name do |t|
          t.string :title
          t.text   :content
        end
      end

      Tenant.find('tenant1').switch
      m1 = Message.create!

      Tenant.find('tenant2').switch
      m2 = Message.create!

      Tenant.find('tenant1').switch
      expect(Message.count).to eql 1

      Tenant.find('tenant2').switch
      expect(Message.count).to eql 1
    end
  end
end
