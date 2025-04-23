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
        poem_count="output/count_poem.txt",
        poem_count_2="output/count_poem_2.txt"
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
        echo {params.poem1} > output/poem.txt
        wc $wc_option output/poem.txt | awk '{{print $1}}' > {output.poem_count}
        echo {params.poem2} > output/poem_2.txt
        wc $wc_option output/poem_2.txt | awk '{{print $1}}' > {output.poem_count_2}
        """

rule arithmetic:
    input:
        poem_count="output/count_poem.txt",
        poem_count_2="output/count_poem_2.txt"
    output:
        "output/arithmetic.txt"
    params:
        method=config["arithmetic_method"],
        add=config["arithmetic_add"],
        multiply=config["arithmetic_multiply"]
    run:
        with open(input.poem_count, "r") as f:
            count1 = int(f.read().strip())
        with open(input.poem_count_2, "r") as f:
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
        poem_count="output/count_poem.txt",
        poem_count_2="output/count_poem_2.txt",
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
        with open(output[0], "w") as f:
            f.write(f"# Summary\n\n")
            f.write(f"Initial counting by: {params.count_method}\n\n")
            f.write(f"### Poem\n\n")
            f.write(f"Contents:\n\n```\n")
            f.write(f"{params.poem}")
            f.write(f"\n```\n\n")
            f.write(f"Count of poem: {open(input.poem_count).read().strip()}\n\n")
            f.write(f"### Poem_2\n\n")
            f.write(f"Contents:\n\n```\n")
            f.write(f"{params.poem_2}")
            f.write(f"\n```\n\n")
            f.write(f"Count of poem_2: {open(input.poem_count_2).read().strip()}\n\n")
            f.write(f"### Arithmetic\n\n")
            f.write(f"Choice of arithmetic operation: {params.arithmetic_method}\n\n")
            if params.arithmetic_method == "Sum, then add a value":
                f.write(f"Added: {params.add}\n\n")
            if params.arithmetic_method == "Sum, then multiply":
                f.write(f"Multiplied by: {params.multiply}\n\n")
            f.write(f"Result of arithmetic operation: {open(input.arithmetic).read().strip()}\n\n")
