using CUDA, Random
import NNlib
using CUDNN:
    cudnnPoolingForward,
    cudnnPoolingForward!,
    cudnnPoolingBackward,
    cudnnGetPoolingNdForwardOutputDim,
    cudnnPoolingDescriptor,
        cudnnPoolingDescriptor_t,
        cudnnCreatePoolingDescriptor,
        cudnnSetPoolingNdDescriptor,
        cudnnDestroyPoolingDescriptor,
    cudnnPoolingMode_t,
        CUDNN_POOLING_MAX,                           # 0,
        CUDNN_POOLING_AVERAGE_COUNT_INCLUDE_PADDING, # 1, /* count for average includes padded values */
        CUDNN_POOLING_AVERAGE_COUNT_EXCLUDE_PADDING, # 2, /* count for average does not include padded values */
        CUDNN_POOLING_MAX_DETERMINISTIC,             # 3
    cudnnNanPropagation_t,
        CUDNN_NOT_PROPAGATE_NAN, # 0
        CUDNN_PROPAGATE_NAN,     # 1
    cudnnTensorFormat_t,
        CUDNN_TENSOR_NCHW,        # 0, /* row major (wStride = 1, hStride = w) */
        CUDNN_TENSOR_NHWC,        # 1, /* feature maps interleaved ( cStride = 1 )*/
        CUDNN_TENSOR_NCHW_VECT_C, # 2, /* each image point is vector of element of C, vector length in data type */
    pooldims

function pooltest(;
                    mode = CUDNN_POOLING_MAX,
                    nanOpt = CUDNN_NOT_PROPAGATE_NAN,
                    window = 2,
                    padding = 0,
                    stride = window,
                    format = CUDNN_TENSOR_NCHW,
                    dataType = Float32,
                    alpha = 1,
                    beta = 0)
    ax = randn(dataType,12,6,4,2)
    N = ndims(ax)
    window = expand(Val(N-2), window)
    stride = expand(Val(N-2), stride)
    padding = expand(Val(N-2), padding)
    pdims = NNlib.PoolDims(ax, window; padding = padding, stride = stride)
    #=
    if mode == CUDNN_POOLING_AVERAGE_COUNT_EXCLUDE_PADDING
        @warn "Pool mode=$mode not yet implemented in NNlib, using INCLUDE instead. See https://github.com/FluxML/NNlib.jl/issues/218" maxlog=1
    end
    if mode == CUDNN_POOLING_MAX_DETERMINISTIC
        @warn "Pool mode=$mode not yet implemented in NNlib, using MAX instead." maxlog=1
    end
    if nanOpt == CUDNN_NOT_PROPAGATE_NAN
        @warn "Pool nanOpt=$nanOpt not yet implemented in NNlib, using PROPAGATE instead. See https://github.com/FluxML/NNlib.jl/issues/218" maxlog=1
    end
    =#
    ay1 = (mode == CUDNN_POOLING_MAX ? NNlib.maxpool(ax, pdims) :
            mode == CUDNN_POOLING_AVERAGE_COUNT_INCLUDE_PADDING ? NNlib.meanpool(ax, pdims) :
            mode == CUDNN_POOLING_AVERAGE_COUNT_EXCLUDE_PADDING ? NNlib.meanpool(ax, pdims) :
            mode == CUDNN_POOLING_MAX_DETERMINISTIC ? NNlib.maxpool(ax, pdims) :
            error("mode=$mode is not supported."))
    ay1 = alpha * ay1
    ay  = randn!(similar(ay1))
    ay2 = ay1 .+ beta * ay
    d = cudnnPoolingDescriptor(mode, nanOpt, Cint(max(2,ndims(ax)-2)), pooldims(window,size(ax)), pooldims(padding,size(ax)), pooldims(stride,size(ax)))
    nhwc(a) = permutedims(a,(3,1,2,4))
    if format === CUDNN_TENSOR_NCHW
        cx, cy = CuArray.((ax, ay))
    else
        cx, cy = CuArray.(nhwc.((ax,ay)))
        ay1, ay2 = nhwc.((ay1, ay2))
    end
    @test ay1 ≈ cudnnPoolingForward(cx; mode, nanOpt, window, padding, stride, format, alpha) |> Array
    @test ay1 ≈ cudnnPoolingForward(cx, d; format, alpha) |> Array
    @test ay2 ≈ cudnnPoolingForward!(copy(cy), cx; mode, nanOpt, window, padding, stride, format, alpha, beta) |> Array
    @test ay2 ≈ cudnnPoolingForward!(copy(cy), cx, d; format, alpha, beta) |> Array
end

expand(::Val{N}, i::NTuple{N}) where {N} = i
expand(::Val{N}, i::Integer) where {N} = ntuple(_ -> i, N)


pooltest()
pooltest(mode = CUDNN_POOLING_AVERAGE_COUNT_INCLUDE_PADDING)
pooltest(mode = CUDNN_POOLING_AVERAGE_COUNT_EXCLUDE_PADDING)
pooltest(mode = CUDNN_POOLING_MAX_DETERMINISTIC)
pooltest(nanOpt = CUDNN_PROPAGATE_NAN)
pooltest(window = 3)
pooltest(padding = 1)
pooltest(stride = 1)
pooltest(format = CUDNN_TENSOR_NHWC)
pooltest(dataType = Float16)
pooltest(alpha = 2)
pooltest(beta = 2)
