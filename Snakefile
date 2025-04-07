configfile: "config.yaml"

rule all:
    input:
        ["output/count_poem.txt", "output/count_poem_2.txt"]

rule build_method_options:
    params:
        poem1=config["poem"],
        poem2=config["poem_2"]
    output:
        opts="output/method_options.txt",
        data_frame="output/discrete_metadata_summary.json",
        continuous_opts="output/continuous_opts.json",
        discrete_opts="output/discrete_opts.json",
        all_opts="output/all_opts.json",
        reduction_opts="output/reduction_opts.json"
    shell:
        """
        echo "[\\"bytes\\", \\"chars\\", \\"words\\"]" > {output.opts}
        """

rule ui_viz:
    input:
        data_frame="output/discrete_metadata_summary.json",
        continuous_opts="output/continuous_opts.json",
        discrete_opts="output/discrete_opts.json",
        all_opts="output/all_opts.json",
        reduction_opts="output/reduction_opts.json"
    output:
        plot_setup="output/plot_setup.json"

# For UI elements that produce outputs used in a snakemake step, we just specify the input/output, so snakemake can infer the dag
rule ui_count_method:
    input:
        "output/method_options.txt"
    output:
        "output/count_method.txt"

rule count:
    params:
        poem1=config["poem"],
        poem2=config["poem_2"],
    input:
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
        echo {params.poem1} | wc $wc_option | awk '{{print $1}}' > {output.poem_count}
        echo {params.poem2} | wc $wc_option | awk '{{print $1}}' > {output.poem_count_2}
        """
