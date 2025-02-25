module Latency

using CUDA
using BenchmarkTools

function main()
    results = BenchmarkGroup()

    base_cmd = Base.julia_cmd()
    if Base.JLOptions().project != C_NULL
        base_cmd = `$base_cmd --project=$(unsafe_string(Base.JLOptions().project))`
    end
    # NOTE: we don't ust Base.active_project() here because of how CI launches this script,
    #       starting with --project in the main CUDA.jl project.

    # time to precompile the package and its dependencies
    precompile_cmd =
        `$base_cmd -e "uuid = Base.UUID(\"052768ef-5323-5732-b1bb-66c8b64840ba\")
                    id = Base.PkgId(uuid, \"CUDA\")
                    Base.compilecache(id)"`
    results["precompile"] = @benchmark run($precompile_cmd) evals=1 seconds=60

    # time to actually import the package
    import_cmd =
        `$base_cmd -e "using CUDA"`
    results["import"] = @benchmark run($import_cmd) evals=1 seconds=30

    # time to initialize CUDA and all other libraries
    initialize_time =
        `$base_cmd -e "using CUDA
                       CUDA.driver_version()"`
    results["initialize"] = @benchmark run($initialize_time) evals=1 seconds=30

    # time to actually compile a kernel
    ttfp_cmd =
        `$base_cmd -e "using CUDA
                    kernel() = return
                    CUDA.code_ptx(devnull, kernel, Tuple{}; kernel=true)"`
    results["ttfp"] = @benchmark run($ttfp_cmd) evals=1 seconds=60

    results
end

end

Latency.main()
