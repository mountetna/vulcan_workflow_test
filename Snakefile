configfile: "config.yaml"

rule all:
    input:
        ["output/count_poem.txt", "output/count_poem_2.txt", "output/summary.md"]

rule count:
    params:
        poem1=config["poem"],
        poem2=config["poem_2"],
        count_method=config["count_method"]
    output:
        poem_1_count="output/count_poem.txt",
        poem_2_count="output/count_poem_2.txt"
    shell:
        """
        method={params.count_method}
        if [[ $method == "bytes" ]]; then
            wc_option="-c"
        elif [[ $method == "chars" ]]; then
            wc_option="-m"
        else
            wc_option="-w"
        fi
        echo -n {params.poem1} > output/poem.txt
        wc $wc_option output/poem.txt | awk '{{print $1}}' > {output.poem_1_count}
        echo -n {params.poem2} > output/poem_2.txt
        wc $wc_option output/poem_2.txt | awk '{{print $1}}' > {output.poem_2_count}
        """

rule id_characters:
    params:
        poem1=config["poem"],
        poem2=config["poem_2"]
    output:
        all_chars="output/all_chars.txt"
    run:
        import json
        text=open(params.poem1).read().strip() + open(params.poem2).read().strip()
        with open(output.all_chars, 'w') as output_file:
            output_file.write(json.dumps(sorted(set(text))))

rule pick_characters: #UI
    input:
        "output/all_chars.txt",
    params:
        ui=True
    output:
        ["output/chars_to_count.json"]

rule count_selected_characters:
    params:
        poem1=config["poem"],
        poem2=config["poem_2"],
    input:
        chars="output/chars_to_count.json"
    output:
        ["output/poem_1_selected_char_count.txt", "output/poem_2_selected_char_count.txt"]
    run:
        import json
        from collections import Counter
        with open(input.chars, "r") as f:
            chars=json.load(f)
        def do_count(s, out):
            counts = Counter(s)
            count = sum([counts[char] for char in chars])
            with open(out, "w") as f:
                f.write(str(count))
        do_count(param.poem1, output[0])
        do_count(param.poem1, output[2])

rule arithmetic:
    input:
        poem_1_count="output/count_poem.txt",
        poem_2_count="output/count_poem_2.txt"
    output:
        "output/arithmetic.txt"
    params:
        method=config["arithmetic_method"],
        add=config["arithmetic_add"],
        multiply=config["arithmetic_multiply"]
    run:
        with open(input.poem_1_count, "r") as f:
            count1 = int(f.read().strip())
        with open(input.poem_2_count, "r") as f:
            count2 = int(f.read().strip())

        if params.method == "Sum, then add a value":
            result = count1 + count2 + params.add
        elif params.method == "Sum, then multiply":
            result = (count1 + count2) * params.multiply
        else:
            result = count1 + count2

        with open(output[0], "w") as f:
            f.write(str(result))

rule summary:
    input:
        poem_1_count="output/count_poem.txt",
        poem_2_count="output/count_poem_2.txt",
        poem_1_char_count="output/poem_1_selected_char_count.txt",
        poem_2_char_count="output/poem_2_selected_char_count.txt",
        chars="output/chars_to_count.json",
        arithmetic="output/arithmetic.txt"
    params:
        poem=config["poem"],
        poem_2=config["poem_2"],
        count_method=config["count_method"],
        arithmetic_method=config["arithmetic_method"],
        add=config["arithmetic_add"],
        multiply=config["arithmetic_multiply"]
    output:
        "output/summary.md"
    run:
        import json
        with open(output[0], "w") as f:
            f.write(f"# Summary\n\n")
            f.write(f"Initial counting by: {params.count_method}\n\n")
            f.write(f"Selected character counting on: {"'"+"', '".join(json.load(open(input.chars)))+"'"}\n\n")
            f.write(f"### Poem 1\n\n")
            f.write(f"Contents:\n\n```\n")
            f.write(f"{params.poem}")
            f.write(f"\n```\n\n")
            f.write(f"Initial count of poem 1: {open(input.poem_1_count).read().strip()}\n\n")
            f.write(f"Selected character count of poem 1: {open(input.poem_1_char_count).read().strip()}\n\n")
            f.write(f"### Poem 2\n\n")
            f.write(f"Contents:\n\n```\n")
            f.write(f"{params.poem_2}")
            f.write(f"\n```\n\n")
            f.write(f"Initial count of poem 2: {open(input.poem_2_count).read().strip()}\n\n")
            f.write(f"Selected character count of poem 2: {open(input.poem_2_char_count).read().strip()}\n\n")
            f.write(f"### Arithmetic\n\n")
            f.write(f"Choice of arithmetic operation: {params.arithmetic_method}\n\n")
            if params.arithmetic_method == "Sum, then add a value":
                f.write(f"Added: {params.add}\n\n")
            if params.arithmetic_method == "Sum, then multiply":
                f.write(f"Multiplied by: {params.multiply}\n\n")
            f.write(f"Result of arithmetic operation: {open(input.arithmetic).read().strip()}\n\n")
