using CUDA, CUTENSOR
using LinearAlgebra

eltypes = ( (Float32, Float32, Float32, Float32),
            (Float32, Float32, Float32, Float16),
            (Float16, Float16, Float16, Float32),
            (ComplexF32, ComplexF32, ComplexF32, ComplexF32),
            (Float64, Float64, Float64, Float64),
            (Float64, Float64, Float64, Float32),
            (ComplexF64, ComplexF64, ComplexF64, ComplexF64),
            (ComplexF64, ComplexF64, ComplexF64, ComplexF32)
            )

# using host memory with CUTENSOR doesn't work on Windows
can_pin = !Sys.iswindows()

@testset for NoA=1:2, NoB=1:2, Nc=1:2
    @testset for (eltyA, eltyB, eltyC, eltyCompute) in eltypes
        # setup
        dmax = 2^div(12, max(NoA+Nc, NoB+Nc, NoA+NoB))
        dimsoA = rand(2:dmax, NoA)
        loA = prod(dimsoA)
        dimsoB = rand(2:dmax, NoB)
        loB = prod(dimsoB)
        dimsc = rand(2:dmax, Nc)
        lc = prod(dimsc)
        allinds = collect('a':'z')
        indsoA = allinds[1:NoA]
        indsoB = allinds[NoA .+ (1:NoB)]
        indsc = allinds[NoA .+ NoB .+ (1:Nc)]
        pA = randperm(NoA + Nc)
        ipA = invperm(pA)
        pB = randperm(Nc + NoB)
        ipB = invperm(pB)
        pC = randperm(NoA + NoB)
        ipC = invperm(pC)
        compute_rtol = (real(eltyCompute) == Float16 || real(eltyC) == Float16) ? 1e-2 : (real(eltyCompute) == Float32 ? 1e-4 : 1e-6)
        dimsA = [dimsoA; dimsc][pA]
        indsA = [indsoA; indsc][pA]
        dimsB = [dimsc; dimsoB][pB]
        indsB = [indsc; indsoB][pB]
        dimsC = [dimsoA; dimsoB][pC]
        indsC = [indsoA; indsoB][pC]

        A = rand(eltyA, (dimsA...,))
        mA = reshape(permutedims(A, ipA), (loA, lc))
        B = rand(eltyB, (dimsB...,))
        mB = reshape(permutedims(B, ipB), (lc, loB))
        C = zeros(eltyC, (dimsC...,))
        dA = CuArray(A)
        dB = CuArray(B)
        dC = CuArray(C)
        # simple case
        opA = CUTENSOR.CUTENSOR_OP_IDENTITY
        opB = CUTENSOR.CUTENSOR_OP_IDENTITY
        opC = CUTENSOR.CUTENSOR_OP_IDENTITY
        opOut = CUTENSOR.CUTENSOR_OP_IDENTITY
        dC = CUTENSOR.contraction!(1, dA, indsA, opA, dB, indsB, opB, 0, dC, indsC, opC, opOut, compute_type=eltyCompute)
        C = collect(dC)
        mC = reshape(permutedims(C, ipC), (loA, loB))
        @test mC ≈ mA * mB rtol=compute_rtol

        # simple case with plan storage
        opA = CUTENSOR.CUTENSOR_OP_IDENTITY
        opB = CUTENSOR.CUTENSOR_OP_IDENTITY
        opC = CUTENSOR.CUTENSOR_OP_IDENTITY
        opOut = CUTENSOR.CUTENSOR_OP_IDENTITY
        plan  = CUTENSOR.plan_contraction(dA, indsA, opA, dB, indsB, opB, dC, indsC, opC, opOut)
        dC = CUTENSOR.contraction!(1, dA, indsA, opA, dB, indsB, opB, 0, dC, indsC, opC, opOut, plan=plan)
        C = collect(dC)
        mC = reshape(permutedims(C, ipC), (loA, loB))
        @test mC ≈ mA * mB

        # simple case with plan storage and compute type
        opA = CUTENSOR.CUTENSOR_OP_IDENTITY
        opB = CUTENSOR.CUTENSOR_OP_IDENTITY
        opC = CUTENSOR.CUTENSOR_OP_IDENTITY
        opOut = CUTENSOR.CUTENSOR_OP_IDENTITY
        plan  = CUTENSOR.plan_contraction(dA, indsA, opA, dB, indsB, opB, dC, indsC, opC, opOut, compute_type=eltyCompute)
        dC = CUTENSOR.contraction!(1, dA, indsA, opA, dB, indsB, opB,
                                    0, dC, indsC, opC, opOut, plan=plan, compute_type=eltyCompute)
        C = collect(dC)
        mC = reshape(permutedims(C, ipC), (loA, loB))
        @test mC ≈ mA * mB rtol=compute_rtol

        # with non-trivial α
        α = rand(eltyCompute)
        dC = CUTENSOR.contraction!(α, dA, indsA, opA, dB, indsB, opB, zero(eltyCompute), dC, indsC, opC, opOut, compute_type=eltyCompute)
        C = collect(dC)
        mC = reshape(permutedims(C, ipC), (loA, loB))
        @test mC ≈ α * mA * mB rtol=compute_rtol

        # with non-trivial β
        C = rand(eltyC, (dimsC...,))
        dC = CuArray(C)
        α = rand(eltyCompute)
        β = rand(eltyCompute)
        copyto!(dC, C)
        dD = CUTENSOR.contraction!(α, dA, indsA, opA, dB, indsB, opB, β, dC, indsC, opC, opOut, compute_type=eltyCompute)
        D = collect(dD)
        mC = reshape(permutedims(C, ipC), (loA, loB))
        mD = reshape(permutedims(D, ipC), (loA, loB))
        @test mD ≈ α * mA * mB + β * mC rtol=compute_rtol
        # with CuTensor objects
        if eltyCompute != Float32 && eltyC != Float16
            ctA = CuTensor(dA, indsA)
            ctB = CuTensor(dB, indsB)
            ctC = CuTensor(dC, indsC)
            ctC = LinearAlgebra.mul!(ctC, ctA, ctB)
            C2, C2inds = collect(ctC)
            mC = reshape(permutedims(C2, ipC), (loA, loB))
            @test mC ≈ mA * mB
            ctC = ctA * ctB
            C2, C2inds = collect(ctC)
            pC2 = convert.(Int, indexin(convert.(Char, C2inds), [indsoA; indsoB]))
            mC = reshape(permutedims(C2, invperm(pC2)), (loA, loB))
            @test mC ≈ mA * mB
        end

        # with conjugation flag for complex arguments
        if !((NoA, NoB, Nc) in ((1,1,3), (1,2,3), (3,1,2)))
        # not supported for these specific cases for unknown reason
            if eltyA <: Complex
                opA   = CUTENSOR.CUTENSOR_OP_CONJ
                opB   = CUTENSOR.CUTENSOR_OP_IDENTITY
                opOut = CUTENSOR.CUTENSOR_OP_IDENTITY
                dC    = CUTENSOR.contraction!(complex(1.0, 0.0), dA, indsA, opA, dB, indsB, opB,
                                                0, dC, indsC, opC, opOut, compute_type=eltyCompute)
                C     = collect(dC)
                mC    = reshape(permutedims(C, ipC), (loA, loB))
                @test mC ≈ conj(mA) * mB rtol=compute_rtol
            end
            if eltyB <: Complex
                opA = CUTENSOR.CUTENSOR_OP_IDENTITY
                opB = CUTENSOR.CUTENSOR_OP_CONJ
                opOut = CUTENSOR.CUTENSOR_OP_IDENTITY
                dC = CUTENSOR.contraction!(complex(1.0, 0.0), dA, indsA, opA, dB, indsB, opB,
                                            complex(0.0, 0.0), dC, indsC, opC, opOut, compute_type=eltyCompute)
                C = collect(dC)
                mC = reshape(permutedims(C, ipC), (loA, loB))
                @test mC ≈ mA*conj(mB) rtol=compute_rtol
            end
            if eltyA <: Complex && eltyB <: Complex
                opA = CUTENSOR.CUTENSOR_OP_CONJ
                opB = CUTENSOR.CUTENSOR_OP_CONJ
                opOut = CUTENSOR.CUTENSOR_OP_IDENTITY
                dC = CUTENSOR.contraction!(one(eltyCompute), dA, indsA, opA, dB, indsB, opB,
                        zero(eltyCompute), dC, indsC, opC, opOut, compute_type=eltyCompute)
                C = collect(dC)
                mC = reshape(permutedims(C, ipC), (loA, loB))
                @test mC ≈ conj(mA)*conj(mB) rtol=compute_rtol
            end
        end
        if can_pin
            Mem.pin(A)
            Mem.pin(B)
            # simple case host side
            Mem.pin(C)
            @test !any(isnan.(C))
            opA = CUTENSOR.CUTENSOR_OP_IDENTITY
            opB = CUTENSOR.CUTENSOR_OP_IDENTITY
            opC = CUTENSOR.CUTENSOR_OP_IDENTITY
            opOut = CUTENSOR.CUTENSOR_OP_IDENTITY
            C  = CUDA.@sync CUTENSOR.contraction!(1, A, indsA, opA, B, indsB, opB, 0, C, indsC, opC, opOut)
            mC = reshape(permutedims(C, ipC), (loA, loB))
            @test !any(isnan.(A))
            @test !any(isnan.(B))
            @test !any(isnan.(mC))
            @test mC ≈ mA * mB rtol=compute_rtol

            # simple case with non-zero α host side
            α = rand(eltyCompute)
            C .= zero(eltyC)
            @test !any(isnan.(C))
            C = CUDA.@sync CUTENSOR.contraction!(α, A, indsA, opA, B, indsB, opB, 0, C, indsC, opC, opOut)
            mC = reshape(permutedims(collect(C), ipC), (loA, loB))
            @test !any(isnan.(mC))
            @test mC ≈ α * mA * mB rtol=compute_rtol

            # simple case with plan storage host-side
            opA = CUTENSOR.CUTENSOR_OP_IDENTITY
            opB = CUTENSOR.CUTENSOR_OP_IDENTITY
            opC = CUTENSOR.CUTENSOR_OP_IDENTITY
            opOut = CUTENSOR.CUTENSOR_OP_IDENTITY
            plan  = CUTENSOR.plan_contraction(A, indsA, opA, B, indsB, opB, C, indsC, opC, opOut)
            C = CUDA.@sync CUTENSOR.contraction!(1, A, indsA, opA, B, indsB, opB, 0, C, indsC, opC, opOut, plan=plan)
            mC = reshape(permutedims(C, ipC), (loA, loB))
            @test !any(isnan.(mC))
            @test mC ≈ mA * mB
        end
    end
end
