module PreProcessing

# using ResumableFunctions

export prepare_files,
       Publication,
       Author


mutable struct Publication
    year    :: Int64
    authors :: Set
end


mutable struct Author
    cnpq           :: Union{String, Nothing}
    publications   :: Union{Array,  Nothing}
    unique_authors :: Union{Array,  Nothing}
    groups         :: Union{Dict,   Nothing}
    n_max_coauth   :: Union{Int64,  Nothing}
    co_oc_matrix   :: Union{Array,  Nothing}
    adj_list       :: Union{Dict,   Nothing}
    qtd_of_publ    :: Union{Int64,  Nothing}
    function Author(cnpq=nothing, p=nothing, u_a=nothing, gr=nothing, n_max_coauth=nothing,co_oc_matrix=nothing, adj=nothing, qtd=nothing)
        new(cnpq, p, u_a, gr, n_max_coauth, co_oc_matrix, adj, qtd)
    end

end



norm(x) = strip(x) |> string |> lowercase
Base.zero(t::Type{AbstractArray}) = [] #
Base.zero(t::Type{Any}) = []           # Sadly, this don't work

function get_table_and_adj(path_to_file)
    authors_set = Dict{String,Integer}()
    adj_list = Dict{Integer,Set{Integer}}()
    author_indx = 1
    for (i,line) in enumerate(readlines(path_to_file))
        yr, authors = split(line, " @ ")
        authors = split(authors, ";")
        last_indxs = []
        for author in authors
            indx = author_indx
            if !haskey(authors_set, author)
                push!(authors_set, author=>author_indx)
                indx = author_indx
                author_indx+=1
            end
            push!(last_indxs, indx)
        end
        push!(adj_list, i=>Set(last_indxs))
    end

    # co_oc_matrix = zeros(Any, author_indx, author_indx)
    co_oc_matrix = [Int64[] for _=1:author_indx, _=1:author_indx]

    for (publ_indx, line) in enumerate(readlines(path_to_file))
        _, authors = split(line, " @ ") |> (x)->(parse(Int64,x[1]),split(x[2],";"))

        for (i, author1) in enumerate(authors)
            for author2 in authors[i:end]
                indx_a1 = authors_set[author1]
                indx_a2 = authors_set[author2]
                push!(co_oc_matrix[indx_a1, indx_a2], publ_indx)  # =  vcat(co_oc_matrix[indx_a1, indx_a2], [publ_indx])

                # println("$indx_a1:$author1  \t\t\t  $indx_a2:$author2  \t\t\t  in:$publ_indx   ls:$(co_oc_matrix[indx_a1, indx_a2])")
            end
        end
    end

    return (co_oc_matrix, adj_list)
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

    author = Author(file, publications, collect(unique_authors), Dict(), max_authors)
    author.groups = groups_by_n(author)
    author.co_oc_matrix, author.adj_list = get_table_and_adj(folder*file)
    author.qtd_of_publ = length(publications)

    return author
end



"""
    prepare_files(folder::String)

Get's `folder` with all input files from lattes, and convert
then to a more efficient format.

Returns: A list of Author
"""
function prepare_files(folder::String)
    contents = []
    for file in readdir(folder)
        push!(contents, transform_csv(folder, file))
        # @yield transform_csv(folder, file)
    end
    return contents
end

end  # module PreProcessing



# using .PreProcessing, JSON
# contents = prepare_files("../test/publications/")
# println(json(contents[3].adj_list, 2))
