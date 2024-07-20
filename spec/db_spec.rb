describe 'database' do
    before do
        `rm -rf test.db`
    end

    def run_scripts(commands)
        raw_output = nil
        IO.popen("./db test.db", "r+") do |pipe|
            commands.each do |command|
                pipe.puts command
            end

            pipe.close_write

            raw_output = pipe.gets(nil)
        end

        raw_output.split("\n")
    end

    it 'inserts and retrieves a row' do
        result = run_scripts([
            "insert 1 user1 user1@example.com",
            "select",
            ".exit"
        ])

        expect(result).to match_array([
            "simpledb > Executed.",
            "simpledb > (1, user1, user1@example.com)",
            "Executed.",
            "simpledb > ",
        ])
    end

    it 'prints error message when table is full' do
        script = (1..1401).map do |i|
          "insert #{i} user#{i} person#{i}@example.com"
        end
        script << ".exit"

        result = run_scripts(script)

        expect(result[-2]).to eq('simpledb > Error: Table full.')
    end

    it 'allows inserting strings that are the maximum length' do
        long_username = "a"*32
        long_email = "a"*255

        script = [
          "insert 1 #{long_username} #{long_email}",
          "select",
          ".exit",
        ]

        result = run_scripts(script)

        expect(result).to match_array([
          "simpledb > Executed.",
          "simpledb > (1, #{long_username}, #{long_email})",
          "Executed.",
          "simpledb > ",
        ])
    end

    it 'prints error message if strings are too long' do
        long_username = "a"*33
        long_email = "a"*256

        script = [
          "insert 1 #{long_username} #{long_email}",
          "select",
          ".exit",
        ]

        result = run_scripts(script)

        expect(result).to match_array([
          "simpledb > String is too long.",
          "simpledb > Executed.",
          "simpledb > ",
        ])
    end

    it 'prints error message if id is negative' do
        neg_id = -1

        script = [
            "insert #{neg_id} user1 user1@example.com",
            "select",
            ".exit",
        ]

        result = run_scripts(script)

        expect(result).to match_array([
            "simpledb > ID must be positive.",
            "simpledb > Executed.",
            "simpledb > ",
        ])
    end

    it 'prints constants' do
        script = [
            ".constants",
            ".exit",
        ]

        result = run_scripts(script)

        expect(result).to match_array([
            "simpledb > Constants:",
            "ROW_SIZE: 293",
            "COMMON_NODE_HEADER_SIZE: 6",
            "LEAF_NODE_HEADER_SIZE: 10",
            "LEAF_NODE_CELL_SIZE: 297",
            "LEAF_NODE_SPACE_FOR_CELLS: 4086",
            "LEAF_NODE_MAX_CELLS: 13",
            "simpledb > ",
        ])
    end

    it 'allows printing out the structure of a one-node btree' do
        script = [3, 1, 2].map do |i|
            "insert #{i} user#{i} person#{i}@example.com"
        end

        script << ".btree"
        script << ".exit"
        
        result = run_scripts(script)

        expect(result).to match_array([
            "simpledb > Executed.",
            "simpledb > Executed.",
            "simpledb > Executed.",
            "simpledb > Tree:",
            "leaf (size 3)",
            "  - 0 : 1",
            "  - 1 : 2",
            "  - 2 : 3",
            "simpledb > "
        ])
    end

    it 'prints an error message if there is a duplicate id' do
        script = [
            "insert 1 user1 person1@example.com",
            "insert 1 user1 person1@example.com",
            "select",
            ".exit",
        ]
            
        result = run_scripts(script)
            
        expect(result).to match_array([
            "simpledb > Executed.",
            "simpledb > Error: Duplicate key.",
            "simpledb > (1, user1, person1@example.com)",
            "Executed.",
            "simpledb > ",
        ])
    end
end