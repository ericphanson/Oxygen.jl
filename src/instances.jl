module Instances
using RelocatableFolders

export oxidize

function extract_filename(include_str::String)
    # Regular expression to match the pattern include("filename")
    match_result = match(r"include\(\"([^\"]+)\"\)", include_str)
    if match_result !== nothing
        return match_result.captures[1]  # Return the captured filename
    else
        return "No filename found"
    end
end

function preprocess_includes(content::String)
    # Regular expression to match include calls
    include_regex = r"include\(\"(.*)\"\)"

    # Function to replace include calls with absolute paths
    function replace_include(match)
        # Extract the path from the match
        path = String(match) |> extract_filename
        absolute_path = @path abspath(joinpath(@__DIR__, path)) 
        # Return the updated include call
        return "include(\"$absolute_path\")"
    end

    # Replace all include calls in the content
    return replace(content, include_regex => replace_include)
end

"""
    load(path::String)

Load a module from a file specified by `path`. The file should define a module.
The module is loaded into the current scope under the name `custom_module`.
"""

function load(path::String)
  
    absolute_path = @path abspath(joinpath(@__DIR__, path)) 

    if !isfile(absolute_path)
        throw("not a valid file")
    end

    # Read the file content
    content = read(absolute_path, String)
    # Preprocess includes to adjust paths
    processed_content = preprocess_includes(content)
    quote
        import Base
        # Execute the preprocessed content
        custom_module = include_string(@__MODULE__, $(processed_content))
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

"""
    setup()
    Load the core file and any other files that are needed
"""
function setup()
    CORE_FILE = @path abspath(joinpath(@__DIR__, "core.jl"))
    combine_loads([
        String(CORE_FILE),
    ])
end

"""
    oxidize()
Create a new self-containedinstance of the Oxygen module. 
This done by creating a new unique module at runtime and loading the Oxygen module into it.
This results in a unique instance of the Oxygen module that can be used independently.
"""
function oxidize()
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