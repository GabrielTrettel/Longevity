include("pre-processing.jl")
using Combinatorics, JSON


@inbounds function process_and_dump(author::Author, out_folder::String)
    # println(json(author.publications, 2))

    TOP_N = 10
    max_t = author.qtd_of_publ
    adj_list = author.publications

    max_n = min(10, author.n_max_coauth)
    biggest_walk, n_of_biggest_walks = (zeros(Int, TOP_N), zeros(Int, TOP_N))

    for t = 1:max_t,  # iterates from first publication to last
        n = 1:max_n   # iterate through all desirable n's

        last_yr = -1
        # if length(adj_list[t].authors) < n #|| length(adj_list[t].authors) > 30
        #     continue
        # end

        for c in combinations(adj_list[t].authors|>collect , n)   # n-combination of authors in time t

            walk = 0
            for publ in author.publications[t:end]        # set of authors from time t to now
                if issubset(Set(c), publ.authors) && publ.year > last_yr
                    walk += 1
                    last_yr = publ.year
                end
            end

            if walk > biggest_walk[n]
                biggest_walk[n] = walk
                n_of_biggest_walks[n] = 1
            elseif walk == biggest_walk[n] && walk != 0
                n_of_biggest_walks[n] += 1
            end
        end
    end

    println("$(author.cnpq) -> $biggest_walk \t $n_of_biggest_walks")

end
