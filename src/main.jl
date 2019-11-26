module Walker

export main

include("pre-processing.jl")
include("walker.jl")

using .PreProcessing, .Walker

function main()
    in_folder, out_folder = ("","")
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

    return 0

    input_data = prepare_files(in_folder)
    process_and_dump(input_data, out_folder)
end


end  # module Walker

using .Walker
main()
