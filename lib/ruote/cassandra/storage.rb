require 'rufus-json'
require 'ruote/storage/base'
require 'ruote/cassandra/version'

module Ruote
  module Cassandra

    # A Cassandra storage for Ruote
    #
    class Storage
      include Ruote::StorageBase

      def initialize(keyspace, servers, options={})
        @keyspace = keyspace
        @servers  = servers
        @options  = options

        put_configuration
      end

      def cassandra
        if @cassandra.nil?
          $stderr.puts "Setting up connection"
          @cassandra = ::Cassandra.new(@keyspace, @servers)
        end

        retry_count = 0
        begin
          # when still responsive, return
          @cassandra.keyspaces
          return @cassandra
        rescue
          $stderr.puts "Re-connection"
          @cassandra = ::Cassandra.new(@keyspace, @servers)

          retry_count += 1
          retry unless retry_count == 10
        end
      end

      def put(doc, opts={})
        rev         = doc['_rev']
        current     = get_doc(doc)
        current_rev = current ? current['_rev'] : nil

        if current_rev && rev != current_rev
          # the given doc is stale, return stored version
          current

        elsif rev && current_rev.nil?
          # the stored version has been deleted
          true

        else
          (type, key) = get_identifiers(doc)

          $stderr.puts "Storing #{type}, #{key}, #{doc}"

          self.cassandra.insert(
            type, key,
            to_json(doc.merge('_rev' => (rev.to_i + 1).to_s))
          )

          nil
        end
      end

      def get(type, key)
        $stderr.puts "Getting #{type}, #{key}"
        res = self.cassandra.get(type, key)
        res == {} ? nil : from_json(res)
      end

      def delete(doc)
        raise ArgumentError.new(
          "can't delete doc without _rev"
        ) unless rev = doc['_rev']

        current = get_doc(doc)

        if current.nil?
          true

        elsif current['_rev'] != rev
          # given doc is stale, return storage version
          current

        else
          (type, key) = get_identifiers(doc)
          self.cassandra.remove(type, key)
          nil
        end
      end

      def get_many(type, key=nil, opts={})
        keys = key ? Array(key) : nil

        return self.cassandra.count_range(type) if keys == nil and opts[:count]

        ids = if keys == nil
          ids(type)
        else
          self.cassandra.get_range(type).select { |doc|
            keys.find { |k| k.match(doc.key) }
          }.collect &:key
        end

        return ids.count if opts[:count]

        docs = ids.inject([]) { |a,id| a << self.cassandra.get(type, id) }

        docs = docs.sort { |a,b| a['_id'] <=> b['_id'] }

        opts[:descending] ? docs.reverse : docs
      end

      def ids(type)
        self.cassandra.get_range(type).collect &:key
      end

      def purge!
      end

      def add_type(type)
      end

      def purge_type!(type)
      end


      # Helper methods
      def get_doc(doc)
        (type, key) = get_identifiers(doc)
        get(type, key)
      end

      def get_identifiers(doc)
        [doc['type'], doc['_id']]
      end

      # Don't put configuration if it's already in
      #
      # (prevent storages from trashing configuration...)
      #
      def put_configuration

        return if get('configurations', 'engine')

        put({ '_id' => 'engine', 'type' => 'configurations' }.merge(@options))
      end

      def to_json(doc)
        doc.merge('put_at' => Ruote.now_to_utc_s)
        doc.each_key do |key|
          doc[key] = Rufus::Json.encode(doc[key])
        end
      end

      def from_json(doc)
        doc.each_key do |key|
          doc[key] = Rufus::Json.decode(doc[key]) rescue doc[key]
        end
      end


      protected :get_doc, :get_identifiers, :put_configuration
    end
  end
end