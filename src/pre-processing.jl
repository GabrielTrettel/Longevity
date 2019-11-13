module PreProcessing

using ResumableFunctions

export prepare_files,
       get_table



mutable struct Publication
    year    :: Int64
    authors :: Set
end


mutable struct Author
    cnpq           :: String
    publications   :: Array{Publication}
    unique_authors :: Array
    groups         :: Dict
    n_max_coauth   :: Int64
    co_oc_matrix
end


norm(x) = strip(x) |> string |> lowercase
Base.zero(t::Type{AbstractArray}) = []
Base.zero(t::Type{Any}) = []

function get_table(path_to_file)
    authors_set = Dict{String,Integer}()
    author_indx = 1
    for line in readlines(path_to_file)
        yr, authors = split(line, " @ ")
        for author in split(authors, ";")
            if !haskey(authors_set, author)
                push!(authors_set, author=>author_indx)
                author_indx+=1
            end
        end
    end

    # co_oc_matrix = zeros(Any, author_indx, author_indx)
    co_oc_matrix = [Any[] for _=1:author_indx, _=1:author_indx]

    for (publ_indx, line) in enumerate(readlines(path_to_file))
        _, authors = split(line, " @ ") |> (x)->(parse(Int64,x[1]),split(x[2],";"))

        for (i, author1) in enumerate(authors)
            for author2 in authors[i:end]
                indx_a1 = authors_set[author1]
                indx_a2 = authors_set[author2]
                push!(co_oc_matrix[indx_a1, indx_a2], publ_indx)# =  vcat(co_oc_matrix[indx_a1, indx_a2], [publ_indx])

                # println("$indx_a1:$author1  \t\t\t  $indx_a2:$author2  \t\t\t  in:$publ_indx   ls:$(co_oc_matrix[indx_a1, indx_a2])")
            end
        end
    end

    return co_oc_matrix
end


function groups_by_n(author::Author)
    publications = author.publications
    groups = Dict()

    for qtd_aut in 1:10
        authors_in_common = filter(x-> length(x.authors) >= qtd_aut, publications)
        authors_in_common = map(x->x.authors, authors_in_common)

        if length(authors_in_common) <= 0 continue end
        qtd_aut_in_common = Set(collect(Iterators.flatten(authors_in_common)))

        push!(groups, qtd_aut=>collect(qtd_aut_in_common))
    end
    return groups
end

function transform_csv(folder, file)
    name_to_number = Dict{String, Int64}()
    a_index = 0
    publications::AbstractArray = []
    unique_authors = Set()
    max_authors = 0

    for line in readlines(folder*file)
        au = Set()
        yr, authors = map(norm, split(line, " @ "))
        authors = Set(map(norm, split(authors, ";")))
        new_authors = Set()

        for a in authors
            if a in keys(name_to_number)
                push!(new_authors, name_to_number[a])
            else
                push!(name_to_number, a=>a_index)
                a_index += 1
                push!(new_authors, name_to_number[a])
            end
        end

        try
            yr = parse(Int64, yr)
        catch
            continue
        end

        if length(new_authors) > max_authors
            max_authors = length(new_authors)
        end

        union!(unique_authors, new_authors)
        push!(publications, Publication(yr, new_authors))
    end

    author = Author(file, publications, collect(unique_authors), Dict(), max_authors, get_table(folder*file)[1])
    author.groups = groups_by_n(author)
    # author.co_oc_matrix = get_table(folder*file)[1]

    return author
end



# """
#     prepare_files(folder::String)
#
# Get's `folder` with all input files from lattes, and convert
# then to a more efficient format.
# """
# @resumable function prepare_files(folder::String)
function prepare_files(folder::String)
    contents = []
    for file in readdir(folder)
        push!(contents, transform_csv(folder, file))
        # @yield transform_csv(folder, file)
    end
    return contents
end

end  # module PreProcessing



using .PreProcessing, JSON
# contents = prepare_files("../test/publications/")
# content = get_table("../test/publications/4723095218834013")

content = get_table("../test/publications/4723484073177616")
println(content,"\n")
# println(json(collect(contents)[3],4))
# for line in eachrow(content)
#     for item in line
#         if length(item) == 0
#             item = [0]
#         end
#         print("$(join(item,","))\t\t\t")
#     end
#     println()
# end
