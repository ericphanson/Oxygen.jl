module MultiInstanceDemo

include("../src/Oxygen.jl")
using .Oxygen
using HTTP

# @get "/" function(req::HTTP.Request)
#     return "hello world!"
# end

app = gen_module()

println(app)



end