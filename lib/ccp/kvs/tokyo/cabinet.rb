module Ccp
  module Kvs
    module Tokyo
      class Cabinet < Base
        include StateMachine

        def initialize(source)
          @source = source
          @db     = HDB.new
        end

        ######################################################################
        ### kvs

        def get(k)
          tryR("get")
          v = @db[k.to_s]
          if v
            return decode(v)
          else
            if @db.ecode == HDB::ENOREC
              return nil
            else
              tokyo_error!("get(%s): " % k)
            end
          end
        end

        def set(k,v)
          tryW("set")
          val = encode(v)
          @db[k.to_s] = val or
            tokyo_error!("set(%s): " % k)
        end

        def del(k)
          tryW("del")
          v = @db[k.to_s]
          if v
            if @db.delete(k.to_s)
              return decode(v)
            else
              tokyo_error!("del(%s): " % k)
            end
          else
            return nil
          end
        end

        def count
          tryR("count")
          return @db.rnum
        end

        ######################################################################
        ### bulk operations (not DRY but fast)

        def read!
          tryR("read!")
          hash = {}
          @db.iterinit
          while k = @db.iternext
            v = @db.get(k) or tokyo_error!("get(%s): " % k)
            hash[k] = decode(v)
          end
          return hash
        end

        ######################################################################
        ### iterator

        def each(&block)
          each_keys do |key|
            block.call(get(key))
          end
        end

        def each_pair(&block)
          each_keys do |key|
            block.call(key, get(key))
          end
        end

        def each_key(&block)
          tryR("each_keys")
          @db.iterinit
          while key = @db.iternext
            block.call(key)
          end
        end

        def each_keys(&block)
          STDERR.puts "DEPRECATION WARNING: #{self.class}#each_keys is deprecated and will be removed in 0.4.0, use each_key instead"
          each_key(&block)
        end

        def keys
          array = []
          each_keys do |key|
            array << key
          end
          return array
        end

      end
    end
  end
end
