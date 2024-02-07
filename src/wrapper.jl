module Wrapper
using RelocatableFolders

export gen_module

"""
    load(path::String)

Load a module from a file specified by `path`. The file should define a module.
The module is loaded into the current scope under the name `custom_module`.
"""
function load(path::String)
    if !isfile(path)
        throw("not a valid file")
    end
    quote
        custom_module = include_string(@__MODULE__, read($path, String))
        using .custom_module
    end 
end

"""
    combine_loads(paths::Vector{String})
concatenate multiple module load calls into a single quote
"""
function combine_loads(paths::Vector{String})
    loads = [load(path) for path in paths]
    return quote
        $(loads...)
    end
end

global const CORE_FILE = @path abspath(joinpath(@__DIR__, "./core.jl"))
    
    

function setup()
    println(isfile(CORE_FILE))
    load(CORE_FILE |> String)
    # combine_loads([
    #     "../core.jl",
    # ])
end

function gen_module()
    # Create the module definition with the macro call for the function definition
    mod_def = Expr(:module, false, gensym(),
        Expr(:block,
            :(using Base),
            setup() # import our load module with more function defnitions
        )
    )
    # Evaluate the module definition to actually create it
    return eval(mod_def)
end

end