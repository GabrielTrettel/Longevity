module bib
export A

struct A
    val::Integer
end

end



module bib2
export f
using .bib1
f(x::A) = x.val

end


module driver
export main
using .bib , .bib2

function main()
    str = A(10)
    # println(f(str))
    println(str)
end
end


using .bib, .driver
main()
