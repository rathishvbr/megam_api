module Megam
    class AssembliesCollection
        include Enumerable

        attr_reader :iterator
        def initialize
            @assemblies = Array.new
            @assemblies_by_name = Hash.new
            @insert_after_idx = nil
        end

        def all_assemblies
            @assemblies
        end

        def [](index)
            @assemblies[index]
        end

        def []=(index, arg)
            is_megam_assemblies(arg)
            @assemblies[index] = arg
            @assemblies_by_name[arg.assembies_name] = index
        end

        def <<(*args)
            args.flatten.each do |a|
                is_megam_assemblies(a)
                @assemblies << a
                @assemblies_by_name[a.name] = @assemblies.length - 1
            end
            self
        end

        # 'push' is an alias method to <<
        alias_method :push, :<<

        def insert(assemblies)
            is_megam_assemblies(assemblies)
            if @insert_after_idx
                # in the middle of executing a run, so any nodes inserted now should
                # be placed after the most recent addition done by the currently executing
                # node
                @assemblies.insert(@insert_after_idx + 1, assemblies)
                # update name -> location mappings and register new node
                @assemblies_by_name.each_key do |key|
                    @assemblies_by_name[key] += 1 if @assemblies_by_name[key] > @insert_after_idx
                end
                @assemblies_by_name[assemblies.name] = @insert_after_idx + 1
                @insert_after_idx += 1
            else
                @assemblies << assemblies
                @assemblies_by_name[assemblies.name] = @assemblies.length - 1
            end
        end

        def each
            @assemblies.each do |assemblies|
                yield assemblies
            end
        end

        def each_index
            @assemblies.each_index do |i|
                yield i
            end
        end

        def empty?
            @assemblies.empty?
        end

        def lookup(assemblies)
            lookup_by = nil
            if assemblies.kind_of?(Megam::Assemblies)
                lookup_by = assemblies.name
            elsif assemblies.kind_of?(String)
                lookup_by = assemblies
            else
                raise ArgumentError, "Must pass a Megam::Assemblies or String to lookup"
            end
            res = @assemblies_by_name[lookup_by]
            unless res
                raise ArgumentError, "Cannot find a node matching #{lookup_by} (did you define it first?)"
            end
            @assemblies[res]
        end

        def to_s
            @assemblies.join(", ")
        end

        def for_json
            to_a.map { |item| item.to_s }
        end

        def to_json(*a)
            Megam::JSONCompat.to_json(for_json, *a)
        end

        def self.json_create(o)
            collection = self.new()
            o["results"].each do |assemblies_list|
                assemblies_array = assemblies_list.kind_of?(Array) ? assemblies_list : [ assemblies_list ]
                assemblies_array.each do |assemblies|
                    collection.insert(assemblies)

                end
            end
            collection
        end

        private

        def is_megam_assemblies(arg)
            unless arg.kind_of?(Megam::Assemblies)
                raise ArgumentError, "Members must be Megam::Assemblies's"
            end
            true
        end
    end
end
