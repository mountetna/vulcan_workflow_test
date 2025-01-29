include: "rules/core.smk"
include: "rules/summary-ui.smk"

configfile: "config.yaml"

rule all:
    input:
        ["output/count_poem.txt", "output/count_poem_2.txt"]

rule build_method_options:
    input:
        poem1=config["poem"],
        poem2=config["poem_2"]
    output:
        opts="output/method_options.txt"
    shell:
        """
        echo "[\"bytes\", \"chars\", \"words\"]" > {output.opts}
        """

# For UI elements that produce outputs used in a snakemake step, we just specify the input/output, so snakemake can infer the dag
rule ui_count_method:
    input:
        "output/method_options.txt"
    output:
        "output/count_method.txt"

rule count:
    input:
        poem1=config["poem"],
        poem2=config["poem_2"],
        count_method="output/count_method.txt"
    output:
        poem_count="output/count_poem.txt",
        poem_count_2="output/count_poem_2.txt"
    shell:
        """
        method_file={input.count_method}
        method_temp=$(cat $method_file)
        method=$(sed -e 's/^"//' -e 's/"$//' <<<"$method_temp")
        if [[ $method == "bytes" ]]; then
            wc_option="-c"
        elif [[ $method == "chars" ]]; then
            wc_option="-m"
        else
            wc_option="-w"
        fi
        echo {input.poem1} | wc $wc_option | awk '{{print $1}}' > {output.poem_count}
        echo {input.poem2} | wc $wc_option | awk '{{print $1}}' > {output.poem_count_2}
        """
