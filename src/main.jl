module Longevity

export main

include("pre-processing.jl")
include("walker.jl")


function main()
    in_folder, out_folder = ("", "")
    try
        in_folder  = ARGS[1] * if ARGS[1][end] == '/' "" else "/" end
        out_folder = ARGS[1] * if ARGS[1][end] == '/' "" else "/" end
    catch
        print("Enter input dir: ")
        in_folder  = readline()
        in_folder *= if in_folder[end] == '/' "" else "/" end

        print("Enter output dir: ")
        out_folder = readline()
        out_folder *= if out_folder[end] == '/' "" else "/" end
    end

    input_data = prepare_files(in_folder)
    @show typeof(input_data)

    # process_and_dump(input_data[2], out_folder)
    @time map(x->process_and_dump(x, out_folder), input_data)

end


end  # module Longevity

using .Longevity
main()
