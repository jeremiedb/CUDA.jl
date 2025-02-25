using CEnum

# CUSPARSE uses CUDA runtime objects, which are compatible with our driver usage
const cudaStream_t = CUstream

# outlined functionality to avoid GC frame allocation
@noinline function throw_api_error(res)
    if res == CUSPARSE_STATUS_ALLOC_FAILED
        throw(OutOfGPUMemoryError())
    else
        throw(CUSPARSEError(res))
    end
end

macro check(ex, errs...)
    check = :(isequal(err, CUSPARSE_STATUS_ALLOC_FAILED))
    for err in errs
        check = :($check || isequal(err, $(esc(err))))
    end

    quote
        res = @retry_reclaim err -> $check $(esc(ex))
        if res != CUSPARSE_STATUS_SUCCESS
            throw_api_error(res)
        end

        nothing
    end
end

mutable struct cusparseContext end

const cusparseHandle_t = Ptr{cusparseContext}

mutable struct cusparseMatDescr end

const cusparseMatDescr_t = Ptr{cusparseMatDescr}

mutable struct csrsv2Info end

const csrsv2Info_t = Ptr{csrsv2Info}

mutable struct csrsm2Info end

const csrsm2Info_t = Ptr{csrsm2Info}

mutable struct bsrsv2Info end

const bsrsv2Info_t = Ptr{bsrsv2Info}

mutable struct bsrsm2Info end

const bsrsm2Info_t = Ptr{bsrsm2Info}

mutable struct csric02Info end

const csric02Info_t = Ptr{csric02Info}

mutable struct bsric02Info end

const bsric02Info_t = Ptr{bsric02Info}

mutable struct csrilu02Info end

const csrilu02Info_t = Ptr{csrilu02Info}

mutable struct bsrilu02Info end

const bsrilu02Info_t = Ptr{bsrilu02Info}

mutable struct csrgemm2Info end

const csrgemm2Info_t = Ptr{csrgemm2Info}

mutable struct csru2csrInfo end

const csru2csrInfo_t = Ptr{csru2csrInfo}

mutable struct cusparseColorInfo end

const cusparseColorInfo_t = Ptr{cusparseColorInfo}

mutable struct pruneInfo end

const pruneInfo_t = Ptr{pruneInfo}

@cenum cusparseStatus_t::UInt32 begin
    CUSPARSE_STATUS_SUCCESS = 0
    CUSPARSE_STATUS_NOT_INITIALIZED = 1
    CUSPARSE_STATUS_ALLOC_FAILED = 2
    CUSPARSE_STATUS_INVALID_VALUE = 3
    CUSPARSE_STATUS_ARCH_MISMATCH = 4
    CUSPARSE_STATUS_MAPPING_ERROR = 5
    CUSPARSE_STATUS_EXECUTION_FAILED = 6
    CUSPARSE_STATUS_INTERNAL_ERROR = 7
    CUSPARSE_STATUS_MATRIX_TYPE_NOT_SUPPORTED = 8
    CUSPARSE_STATUS_ZERO_PIVOT = 9
    CUSPARSE_STATUS_NOT_SUPPORTED = 10
    CUSPARSE_STATUS_INSUFFICIENT_RESOURCES = 11
end

@cenum cusparsePointerMode_t::UInt32 begin
    CUSPARSE_POINTER_MODE_HOST = 0
    CUSPARSE_POINTER_MODE_DEVICE = 1
end

@cenum cusparseAction_t::UInt32 begin
    CUSPARSE_ACTION_SYMBOLIC = 0
    CUSPARSE_ACTION_NUMERIC = 1
end

@cenum cusparseMatrixType_t::UInt32 begin
    CUSPARSE_MATRIX_TYPE_GENERAL = 0
    CUSPARSE_MATRIX_TYPE_SYMMETRIC = 1
    CUSPARSE_MATRIX_TYPE_HERMITIAN = 2
    CUSPARSE_MATRIX_TYPE_TRIANGULAR = 3
end

@cenum cusparseFillMode_t::UInt32 begin
    CUSPARSE_FILL_MODE_LOWER = 0
    CUSPARSE_FILL_MODE_UPPER = 1
end

@cenum cusparseDiagType_t::UInt32 begin
    CUSPARSE_DIAG_TYPE_NON_UNIT = 0
    CUSPARSE_DIAG_TYPE_UNIT = 1
end

@cenum cusparseIndexBase_t::UInt32 begin
    CUSPARSE_INDEX_BASE_ZERO = 0
    CUSPARSE_INDEX_BASE_ONE = 1
end

@cenum cusparseOperation_t::UInt32 begin
    CUSPARSE_OPERATION_NON_TRANSPOSE = 0
    CUSPARSE_OPERATION_TRANSPOSE = 1
    CUSPARSE_OPERATION_CONJUGATE_TRANSPOSE = 2
end

@cenum cusparseDirection_t::UInt32 begin
    CUSPARSE_DIRECTION_ROW = 0
    CUSPARSE_DIRECTION_COLUMN = 1
end

@cenum cusparseSolvePolicy_t::UInt32 begin
    CUSPARSE_SOLVE_POLICY_NO_LEVEL = 0
    CUSPARSE_SOLVE_POLICY_USE_LEVEL = 1
end

@cenum cusparseColorAlg_t::UInt32 begin
    CUSPARSE_COLOR_ALG0 = 0
    CUSPARSE_COLOR_ALG1 = 1
end

@cenum cusparseAlgMode_t::UInt32 begin
    CUSPARSE_ALG_MERGE_PATH = 0
end

@checked function cusparseCreate(handle)
    initialize_context()
    @ccall libcusparse.cusparseCreate(handle::Ptr{cusparseHandle_t})::cusparseStatus_t
end

@checked function cusparseDestroy(handle)
    initialize_context()
    @ccall libcusparse.cusparseDestroy(handle::cusparseHandle_t)::cusparseStatus_t
end

@checked function cusparseGetVersion(handle, version)
    @ccall libcusparse.cusparseGetVersion(handle::cusparseHandle_t,
                                          version::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseGetProperty(type, value)
    @ccall libcusparse.cusparseGetProperty(type::libraryPropertyType,
                                           value::Ptr{Cint})::cusparseStatus_t
end

function cusparseGetErrorName(status)
    @ccall libcusparse.cusparseGetErrorName(status::cusparseStatus_t)::Cstring
end

function cusparseGetErrorString(status)
    @ccall libcusparse.cusparseGetErrorString(status::cusparseStatus_t)::Cstring
end

@checked function cusparseSetStream(handle, streamId)
    initialize_context()
    @ccall libcusparse.cusparseSetStream(handle::cusparseHandle_t,
                                         streamId::cudaStream_t)::cusparseStatus_t
end

@checked function cusparseGetStream(handle, streamId)
    initialize_context()
    @ccall libcusparse.cusparseGetStream(handle::cusparseHandle_t,
                                         streamId::Ptr{cudaStream_t})::cusparseStatus_t
end

@checked function cusparseGetPointerMode(handle, mode)
    initialize_context()
    @ccall libcusparse.cusparseGetPointerMode(handle::cusparseHandle_t,
                                              mode::Ptr{cusparsePointerMode_t})::cusparseStatus_t
end

@checked function cusparseSetPointerMode(handle, mode)
    initialize_context()
    @ccall libcusparse.cusparseSetPointerMode(handle::cusparseHandle_t,
                                              mode::cusparsePointerMode_t)::cusparseStatus_t
end

# typedef void ( * cusparseLoggerCallback_t ) ( int logLevel , const char * functionName , const char * message )
const cusparseLoggerCallback_t = Ptr{Cvoid}

@checked function cusparseLoggerSetCallback(callback)
    initialize_context()
    @ccall libcusparse.cusparseLoggerSetCallback(callback::cusparseLoggerCallback_t)::cusparseStatus_t
end

@checked function cusparseLoggerSetFile(file)
    initialize_context()
    @ccall libcusparse.cusparseLoggerSetFile(file::Ptr{Libc.FILE})::cusparseStatus_t
end

@checked function cusparseLoggerOpenFile(logFile)
    initialize_context()
    @ccall libcusparse.cusparseLoggerOpenFile(logFile::Cstring)::cusparseStatus_t
end

@checked function cusparseLoggerSetLevel(level)
    initialize_context()
    @ccall libcusparse.cusparseLoggerSetLevel(level::Cint)::cusparseStatus_t
end

@checked function cusparseLoggerSetMask(mask)
    initialize_context()
    @ccall libcusparse.cusparseLoggerSetMask(mask::Cint)::cusparseStatus_t
end

@checked function cusparseLoggerForceDisable()
    initialize_context()
    @ccall libcusparse.cusparseLoggerForceDisable()::cusparseStatus_t
end

@checked function cusparseCreateMatDescr(descrA)
    initialize_context()
    @ccall libcusparse.cusparseCreateMatDescr(descrA::Ptr{cusparseMatDescr_t})::cusparseStatus_t
end

@checked function cusparseDestroyMatDescr(descrA)
    initialize_context()
    @ccall libcusparse.cusparseDestroyMatDescr(descrA::cusparseMatDescr_t)::cusparseStatus_t
end

@checked function cusparseCopyMatDescr(dest, src)
    initialize_context()
    @ccall libcusparse.cusparseCopyMatDescr(dest::cusparseMatDescr_t,
                                            src::cusparseMatDescr_t)::cusparseStatus_t
end

@checked function cusparseSetMatType(descrA, type)
    initialize_context()
    @ccall libcusparse.cusparseSetMatType(descrA::cusparseMatDescr_t,
                                          type::cusparseMatrixType_t)::cusparseStatus_t
end

function cusparseGetMatType(descrA)
    initialize_context()
    @ccall libcusparse.cusparseGetMatType(descrA::cusparseMatDescr_t)::cusparseMatrixType_t
end

@checked function cusparseSetMatFillMode(descrA, fillMode)
    initialize_context()
    @ccall libcusparse.cusparseSetMatFillMode(descrA::cusparseMatDescr_t,
                                              fillMode::cusparseFillMode_t)::cusparseStatus_t
end

function cusparseGetMatFillMode(descrA)
    initialize_context()
    @ccall libcusparse.cusparseGetMatFillMode(descrA::cusparseMatDescr_t)::cusparseFillMode_t
end

@checked function cusparseSetMatDiagType(descrA, diagType)
    initialize_context()
    @ccall libcusparse.cusparseSetMatDiagType(descrA::cusparseMatDescr_t,
                                              diagType::cusparseDiagType_t)::cusparseStatus_t
end

function cusparseGetMatDiagType(descrA)
    initialize_context()
    @ccall libcusparse.cusparseGetMatDiagType(descrA::cusparseMatDescr_t)::cusparseDiagType_t
end

@checked function cusparseSetMatIndexBase(descrA, base)
    initialize_context()
    @ccall libcusparse.cusparseSetMatIndexBase(descrA::cusparseMatDescr_t,
                                               base::cusparseIndexBase_t)::cusparseStatus_t
end

function cusparseGetMatIndexBase(descrA)
    initialize_context()
    @ccall libcusparse.cusparseGetMatIndexBase(descrA::cusparseMatDescr_t)::cusparseIndexBase_t
end

@checked function cusparseCreateCsrsv2Info(info)
    initialize_context()
    @ccall libcusparse.cusparseCreateCsrsv2Info(info::Ptr{csrsv2Info_t})::cusparseStatus_t
end

@checked function cusparseDestroyCsrsv2Info(info)
    initialize_context()
    @ccall libcusparse.cusparseDestroyCsrsv2Info(info::csrsv2Info_t)::cusparseStatus_t
end

@checked function cusparseCreateCsric02Info(info)
    initialize_context()
    @ccall libcusparse.cusparseCreateCsric02Info(info::Ptr{csric02Info_t})::cusparseStatus_t
end

@checked function cusparseDestroyCsric02Info(info)
    initialize_context()
    @ccall libcusparse.cusparseDestroyCsric02Info(info::csric02Info_t)::cusparseStatus_t
end

@checked function cusparseCreateBsric02Info(info)
    initialize_context()
    @ccall libcusparse.cusparseCreateBsric02Info(info::Ptr{bsric02Info_t})::cusparseStatus_t
end

@checked function cusparseDestroyBsric02Info(info)
    initialize_context()
    @ccall libcusparse.cusparseDestroyBsric02Info(info::bsric02Info_t)::cusparseStatus_t
end

@checked function cusparseCreateCsrilu02Info(info)
    initialize_context()
    @ccall libcusparse.cusparseCreateCsrilu02Info(info::Ptr{csrilu02Info_t})::cusparseStatus_t
end

@checked function cusparseDestroyCsrilu02Info(info)
    initialize_context()
    @ccall libcusparse.cusparseDestroyCsrilu02Info(info::csrilu02Info_t)::cusparseStatus_t
end

@checked function cusparseCreateBsrilu02Info(info)
    initialize_context()
    @ccall libcusparse.cusparseCreateBsrilu02Info(info::Ptr{bsrilu02Info_t})::cusparseStatus_t
end

@checked function cusparseDestroyBsrilu02Info(info)
    initialize_context()
    @ccall libcusparse.cusparseDestroyBsrilu02Info(info::bsrilu02Info_t)::cusparseStatus_t
end

@checked function cusparseCreateBsrsv2Info(info)
    initialize_context()
    @ccall libcusparse.cusparseCreateBsrsv2Info(info::Ptr{bsrsv2Info_t})::cusparseStatus_t
end

@checked function cusparseDestroyBsrsv2Info(info)
    initialize_context()
    @ccall libcusparse.cusparseDestroyBsrsv2Info(info::bsrsv2Info_t)::cusparseStatus_t
end

@checked function cusparseCreateBsrsm2Info(info)
    initialize_context()
    @ccall libcusparse.cusparseCreateBsrsm2Info(info::Ptr{bsrsm2Info_t})::cusparseStatus_t
end

@checked function cusparseDestroyBsrsm2Info(info)
    initialize_context()
    @ccall libcusparse.cusparseDestroyBsrsm2Info(info::bsrsm2Info_t)::cusparseStatus_t
end

@checked function cusparseCreateCsru2csrInfo(info)
    initialize_context()
    @ccall libcusparse.cusparseCreateCsru2csrInfo(info::Ptr{csru2csrInfo_t})::cusparseStatus_t
end

@checked function cusparseDestroyCsru2csrInfo(info)
    initialize_context()
    @ccall libcusparse.cusparseDestroyCsru2csrInfo(info::csru2csrInfo_t)::cusparseStatus_t
end

@checked function cusparseCreateColorInfo(info)
    initialize_context()
    @ccall libcusparse.cusparseCreateColorInfo(info::Ptr{cusparseColorInfo_t})::cusparseStatus_t
end

@checked function cusparseDestroyColorInfo(info)
    initialize_context()
    @ccall libcusparse.cusparseDestroyColorInfo(info::cusparseColorInfo_t)::cusparseStatus_t
end

@checked function cusparseSetColorAlgs(info, alg)
    initialize_context()
    @ccall libcusparse.cusparseSetColorAlgs(info::cusparseColorInfo_t,
                                            alg::cusparseColorAlg_t)::cusparseStatus_t
end

@checked function cusparseGetColorAlgs(info, alg)
    initialize_context()
    @ccall libcusparse.cusparseGetColorAlgs(info::cusparseColorInfo_t,
                                            alg::Ptr{cusparseColorAlg_t})::cusparseStatus_t
end

@checked function cusparseCreatePruneInfo(info)
    initialize_context()
    @ccall libcusparse.cusparseCreatePruneInfo(info::Ptr{pruneInfo_t})::cusparseStatus_t
end

@checked function cusparseDestroyPruneInfo(info)
    initialize_context()
    @ccall libcusparse.cusparseDestroyPruneInfo(info::pruneInfo_t)::cusparseStatus_t
end

@checked function cusparseSaxpyi(handle, nnz, alpha, xVal, xInd, y, idxBase)
    initialize_context()
    @ccall libcusparse.cusparseSaxpyi(handle::cusparseHandle_t, nnz::Cint,
                                      alpha::Ref{Cfloat}, xVal::CuPtr{Cfloat},
                                      xInd::CuPtr{Cint}, y::CuPtr{Cfloat},
                                      idxBase::cusparseIndexBase_t)::cusparseStatus_t
end

@checked function cusparseDaxpyi(handle, nnz, alpha, xVal, xInd, y, idxBase)
    initialize_context()
    @ccall libcusparse.cusparseDaxpyi(handle::cusparseHandle_t, nnz::Cint,
                                      alpha::Ref{Cdouble}, xVal::CuPtr{Cdouble},
                                      xInd::CuPtr{Cint}, y::CuPtr{Cdouble},
                                      idxBase::cusparseIndexBase_t)::cusparseStatus_t
end

@checked function cusparseCaxpyi(handle, nnz, alpha, xVal, xInd, y, idxBase)
    initialize_context()
    @ccall libcusparse.cusparseCaxpyi(handle::cusparseHandle_t, nnz::Cint,
                                      alpha::Ref{cuComplex}, xVal::CuPtr{cuComplex},
                                      xInd::CuPtr{Cint}, y::CuPtr{cuComplex},
                                      idxBase::cusparseIndexBase_t)::cusparseStatus_t
end

@checked function cusparseZaxpyi(handle, nnz, alpha, xVal, xInd, y, idxBase)
    initialize_context()
    @ccall libcusparse.cusparseZaxpyi(handle::cusparseHandle_t, nnz::Cint,
                                      alpha::Ref{cuDoubleComplex},
                                      xVal::CuPtr{cuDoubleComplex}, xInd::CuPtr{Cint},
                                      y::CuPtr{cuDoubleComplex},
                                      idxBase::cusparseIndexBase_t)::cusparseStatus_t
end

@checked function cusparseSgthr(handle, nnz, y, xVal, xInd, idxBase)
    initialize_context()
    @ccall libcusparse.cusparseSgthr(handle::cusparseHandle_t, nnz::Cint, y::CuPtr{Cfloat},
                                     xVal::CuPtr{Cfloat}, xInd::CuPtr{Cint},
                                     idxBase::cusparseIndexBase_t)::cusparseStatus_t
end

@checked function cusparseDgthr(handle, nnz, y, xVal, xInd, idxBase)
    initialize_context()
    @ccall libcusparse.cusparseDgthr(handle::cusparseHandle_t, nnz::Cint, y::CuPtr{Cdouble},
                                     xVal::CuPtr{Cdouble}, xInd::CuPtr{Cint},
                                     idxBase::cusparseIndexBase_t)::cusparseStatus_t
end

@checked function cusparseCgthr(handle, nnz, y, xVal, xInd, idxBase)
    initialize_context()
    @ccall libcusparse.cusparseCgthr(handle::cusparseHandle_t, nnz::Cint,
                                     y::CuPtr{cuComplex}, xVal::CuPtr{cuComplex},
                                     xInd::CuPtr{Cint},
                                     idxBase::cusparseIndexBase_t)::cusparseStatus_t
end

@checked function cusparseZgthr(handle, nnz, y, xVal, xInd, idxBase)
    initialize_context()
    @ccall libcusparse.cusparseZgthr(handle::cusparseHandle_t, nnz::Cint,
                                     y::CuPtr{cuDoubleComplex},
                                     xVal::CuPtr{cuDoubleComplex}, xInd::CuPtr{Cint},
                                     idxBase::cusparseIndexBase_t)::cusparseStatus_t
end

@checked function cusparseSgthrz(handle, nnz, y, xVal, xInd, idxBase)
    initialize_context()
    @ccall libcusparse.cusparseSgthrz(handle::cusparseHandle_t, nnz::Cint, y::CuPtr{Cfloat},
                                      xVal::CuPtr{Cfloat}, xInd::CuPtr{Cint},
                                      idxBase::cusparseIndexBase_t)::cusparseStatus_t
end

@checked function cusparseDgthrz(handle, nnz, y, xVal, xInd, idxBase)
    initialize_context()
    @ccall libcusparse.cusparseDgthrz(handle::cusparseHandle_t, nnz::Cint,
                                      y::CuPtr{Cdouble}, xVal::CuPtr{Cdouble},
                                      xInd::CuPtr{Cint},
                                      idxBase::cusparseIndexBase_t)::cusparseStatus_t
end

@checked function cusparseCgthrz(handle, nnz, y, xVal, xInd, idxBase)
    initialize_context()
    @ccall libcusparse.cusparseCgthrz(handle::cusparseHandle_t, nnz::Cint,
                                      y::CuPtr{cuComplex}, xVal::CuPtr{cuComplex},
                                      xInd::CuPtr{Cint},
                                      idxBase::cusparseIndexBase_t)::cusparseStatus_t
end

@checked function cusparseZgthrz(handle, nnz, y, xVal, xInd, idxBase)
    initialize_context()
    @ccall libcusparse.cusparseZgthrz(handle::cusparseHandle_t, nnz::Cint,
                                      y::CuPtr{cuDoubleComplex},
                                      xVal::CuPtr{cuDoubleComplex}, xInd::CuPtr{Cint},
                                      idxBase::cusparseIndexBase_t)::cusparseStatus_t
end

@checked function cusparseSsctr(handle, nnz, xVal, xInd, y, idxBase)
    initialize_context()
    @ccall libcusparse.cusparseSsctr(handle::cusparseHandle_t, nnz::Cint,
                                     xVal::CuPtr{Cfloat}, xInd::CuPtr{Cint},
                                     y::CuPtr{Cfloat},
                                     idxBase::cusparseIndexBase_t)::cusparseStatus_t
end

@checked function cusparseDsctr(handle, nnz, xVal, xInd, y, idxBase)
    initialize_context()
    @ccall libcusparse.cusparseDsctr(handle::cusparseHandle_t, nnz::Cint,
                                     xVal::CuPtr{Cdouble}, xInd::CuPtr{Cint},
                                     y::CuPtr{Cdouble},
                                     idxBase::cusparseIndexBase_t)::cusparseStatus_t
end

@checked function cusparseCsctr(handle, nnz, xVal, xInd, y, idxBase)
    initialize_context()
    @ccall libcusparse.cusparseCsctr(handle::cusparseHandle_t, nnz::Cint,
                                     xVal::CuPtr{cuComplex}, xInd::CuPtr{Cint},
                                     y::CuPtr{cuComplex},
                                     idxBase::cusparseIndexBase_t)::cusparseStatus_t
end

@checked function cusparseZsctr(handle, nnz, xVal, xInd, y, idxBase)
    initialize_context()
    @ccall libcusparse.cusparseZsctr(handle::cusparseHandle_t, nnz::Cint,
                                     xVal::CuPtr{cuDoubleComplex}, xInd::CuPtr{Cint},
                                     y::CuPtr{cuDoubleComplex},
                                     idxBase::cusparseIndexBase_t)::cusparseStatus_t
end

@checked function cusparseSroti(handle, nnz, xVal, xInd, y, c, s, idxBase)
    initialize_context()
    @ccall libcusparse.cusparseSroti(handle::cusparseHandle_t, nnz::Cint,
                                     xVal::CuPtr{Cfloat}, xInd::CuPtr{Cint},
                                     y::CuPtr{Cfloat}, c::Ref{Cfloat}, s::Ref{Cfloat},
                                     idxBase::cusparseIndexBase_t)::cusparseStatus_t
end

@checked function cusparseDroti(handle, nnz, xVal, xInd, y, c, s, idxBase)
    initialize_context()
    @ccall libcusparse.cusparseDroti(handle::cusparseHandle_t, nnz::Cint,
                                     xVal::CuPtr{Cdouble}, xInd::CuPtr{Cint},
                                     y::CuPtr{Cdouble}, c::Ref{Cdouble}, s::Ref{Cdouble},
                                     idxBase::cusparseIndexBase_t)::cusparseStatus_t
end

@checked function cusparseSgemvi(handle, transA, m, n, alpha, A, lda, nnz, xVal, xInd, beta,
                                 y, idxBase, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSgemvi(handle::cusparseHandle_t, transA::cusparseOperation_t,
                                      m::Cint, n::Cint, alpha::Ref{Cfloat},
                                      A::CuPtr{Cfloat}, lda::Cint, nnz::Cint,
                                      xVal::CuPtr{Cfloat}, xInd::CuPtr{Cint},
                                      beta::Ref{Cfloat}, y::CuPtr{Cfloat},
                                      idxBase::cusparseIndexBase_t,
                                      pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSgemvi_bufferSize(handle, transA, m, n, nnz, pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseSgemvi_bufferSize(handle::cusparseHandle_t,
                                                 transA::cusparseOperation_t, m::Cint,
                                                 n::Cint, nnz::Cint,
                                                 pBufferSize::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseDgemvi(handle, transA, m, n, alpha, A, lda, nnz, xVal, xInd, beta,
                                 y, idxBase, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDgemvi(handle::cusparseHandle_t, transA::cusparseOperation_t,
                                      m::Cint, n::Cint, alpha::Ref{Cdouble},
                                      A::CuPtr{Cdouble}, lda::Cint, nnz::Cint,
                                      xVal::CuPtr{Cdouble}, xInd::CuPtr{Cint},
                                      beta::Ref{Cdouble}, y::CuPtr{Cdouble},
                                      idxBase::cusparseIndexBase_t,
                                      pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDgemvi_bufferSize(handle, transA, m, n, nnz, pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseDgemvi_bufferSize(handle::cusparseHandle_t,
                                                 transA::cusparseOperation_t, m::Cint,
                                                 n::Cint, nnz::Cint,
                                                 pBufferSize::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseCgemvi(handle, transA, m, n, alpha, A, lda, nnz, xVal, xInd, beta,
                                 y, idxBase, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCgemvi(handle::cusparseHandle_t, transA::cusparseOperation_t,
                                      m::Cint, n::Cint, alpha::Ref{cuComplex},
                                      A::CuPtr{cuComplex}, lda::Cint, nnz::Cint,
                                      xVal::CuPtr{cuComplex}, xInd::CuPtr{Cint},
                                      beta::Ref{cuComplex}, y::CuPtr{cuComplex},
                                      idxBase::cusparseIndexBase_t,
                                      pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCgemvi_bufferSize(handle, transA, m, n, nnz, pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseCgemvi_bufferSize(handle::cusparseHandle_t,
                                                 transA::cusparseOperation_t, m::Cint,
                                                 n::Cint, nnz::Cint,
                                                 pBufferSize::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseZgemvi(handle, transA, m, n, alpha, A, lda, nnz, xVal, xInd, beta,
                                 y, idxBase, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZgemvi(handle::cusparseHandle_t, transA::cusparseOperation_t,
                                      m::Cint, n::Cint, alpha::Ref{cuDoubleComplex},
                                      A::CuPtr{cuDoubleComplex}, lda::Cint, nnz::Cint,
                                      xVal::CuPtr{cuDoubleComplex}, xInd::CuPtr{Cint},
                                      beta::Ref{cuDoubleComplex}, y::CuPtr{cuDoubleComplex},
                                      idxBase::cusparseIndexBase_t,
                                      pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZgemvi_bufferSize(handle, transA, m, n, nnz, pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseZgemvi_bufferSize(handle::cusparseHandle_t,
                                                 transA::cusparseOperation_t, m::Cint,
                                                 n::Cint, nnz::Cint,
                                                 pBufferSize::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseCsrmvEx_bufferSize(handle, alg, transA, m, n, nnz, alpha,
                                             alphatype, descrA, csrValA, csrValAtype,
                                             csrRowPtrA, csrColIndA, x, xtype, beta,
                                             betatype, y, ytype, executiontype,
                                             bufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseCsrmvEx_bufferSize(handle::cusparseHandle_t,
                                                  alg::cusparseAlgMode_t,
                                                  transA::cusparseOperation_t, m::Cint,
                                                  n::Cint, nnz::Cint, alpha::Ptr{Cvoid},
                                                  alphatype::cudaDataType,
                                                  descrA::cusparseMatDescr_t,
                                                  csrValA::CuPtr{Cvoid},
                                                  csrValAtype::cudaDataType,
                                                  csrRowPtrA::CuPtr{Cint},
                                                  csrColIndA::CuPtr{Cint}, x::CuPtr{Cvoid},
                                                  xtype::cudaDataType, beta::Ptr{Cvoid},
                                                  betatype::cudaDataType, y::CuPtr{Cvoid},
                                                  ytype::cudaDataType,
                                                  executiontype::cudaDataType,
                                                  bufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseCsrmvEx(handle, alg, transA, m, n, nnz, alpha, alphatype, descrA,
                                  csrValA, csrValAtype, csrRowPtrA, csrColIndA, x, xtype,
                                  beta, betatype, y, ytype, executiontype, buffer)
    initialize_context()
    @ccall libcusparse.cusparseCsrmvEx(handle::cusparseHandle_t, alg::cusparseAlgMode_t,
                                       transA::cusparseOperation_t, m::Cint, n::Cint,
                                       nnz::Cint, alpha::Ptr{Cvoid},
                                       alphatype::cudaDataType, descrA::cusparseMatDescr_t,
                                       csrValA::CuPtr{Cvoid}, csrValAtype::cudaDataType,
                                       csrRowPtrA::CuPtr{Cint}, csrColIndA::CuPtr{Cint},
                                       x::CuPtr{Cvoid}, xtype::cudaDataType,
                                       beta::Ptr{Cvoid}, betatype::cudaDataType,
                                       y::CuPtr{Cvoid}, ytype::cudaDataType,
                                       executiontype::cudaDataType,
                                       buffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSbsrmv(handle, dirA, transA, mb, nb, nnzb, alpha, descrA,
                                 bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA,
                                 blockDim, x, beta, y)
    initialize_context()
    @ccall libcusparse.cusparseSbsrmv(handle::cusparseHandle_t, dirA::cusparseDirection_t,
                                      transA::cusparseOperation_t, mb::Cint, nb::Cint,
                                      nnzb::Cint, alpha::Ref{Cfloat},
                                      descrA::cusparseMatDescr_t,
                                      bsrSortedValA::CuPtr{Cfloat},
                                      bsrSortedRowPtrA::CuPtr{Cint},
                                      bsrSortedColIndA::CuPtr{Cint}, blockDim::Cint,
                                      x::CuPtr{Cfloat}, beta::Ref{Cfloat},
                                      y::CuPtr{Cfloat})::cusparseStatus_t
end

@checked function cusparseDbsrmv(handle, dirA, transA, mb, nb, nnzb, alpha, descrA,
                                 bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA,
                                 blockDim, x, beta, y)
    initialize_context()
    @ccall libcusparse.cusparseDbsrmv(handle::cusparseHandle_t, dirA::cusparseDirection_t,
                                      transA::cusparseOperation_t, mb::Cint, nb::Cint,
                                      nnzb::Cint, alpha::Ref{Cdouble},
                                      descrA::cusparseMatDescr_t,
                                      bsrSortedValA::CuPtr{Cdouble},
                                      bsrSortedRowPtrA::CuPtr{Cint},
                                      bsrSortedColIndA::CuPtr{Cint}, blockDim::Cint,
                                      x::CuPtr{Cdouble}, beta::Ref{Cdouble},
                                      y::CuPtr{Cdouble})::cusparseStatus_t
end

@checked function cusparseCbsrmv(handle, dirA, transA, mb, nb, nnzb, alpha, descrA,
                                 bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA,
                                 blockDim, x, beta, y)
    initialize_context()
    @ccall libcusparse.cusparseCbsrmv(handle::cusparseHandle_t, dirA::cusparseDirection_t,
                                      transA::cusparseOperation_t, mb::Cint, nb::Cint,
                                      nnzb::Cint, alpha::Ref{cuComplex},
                                      descrA::cusparseMatDescr_t,
                                      bsrSortedValA::CuPtr{cuComplex},
                                      bsrSortedRowPtrA::CuPtr{Cint},
                                      bsrSortedColIndA::CuPtr{Cint}, blockDim::Cint,
                                      x::CuPtr{cuComplex}, beta::Ref{cuComplex},
                                      y::CuPtr{cuComplex})::cusparseStatus_t
end

@checked function cusparseZbsrmv(handle, dirA, transA, mb, nb, nnzb, alpha, descrA,
                                 bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA,
                                 blockDim, x, beta, y)
    initialize_context()
    @ccall libcusparse.cusparseZbsrmv(handle::cusparseHandle_t, dirA::cusparseDirection_t,
                                      transA::cusparseOperation_t, mb::Cint, nb::Cint,
                                      nnzb::Cint, alpha::Ref{cuDoubleComplex},
                                      descrA::cusparseMatDescr_t,
                                      bsrSortedValA::CuPtr{cuDoubleComplex},
                                      bsrSortedRowPtrA::CuPtr{Cint},
                                      bsrSortedColIndA::CuPtr{Cint}, blockDim::Cint,
                                      x::CuPtr{cuDoubleComplex}, beta::Ref{cuDoubleComplex},
                                      y::CuPtr{cuDoubleComplex})::cusparseStatus_t
end

@checked function cusparseSbsrxmv(handle, dirA, transA, sizeOfMask, mb, nb, nnzb, alpha,
                                  descrA, bsrSortedValA, bsrSortedMaskPtrA,
                                  bsrSortedRowPtrA, bsrSortedEndPtrA, bsrSortedColIndA,
                                  blockDim, x, beta, y)
    initialize_context()
    @ccall libcusparse.cusparseSbsrxmv(handle::cusparseHandle_t, dirA::cusparseDirection_t,
                                       transA::cusparseOperation_t, sizeOfMask::Cint,
                                       mb::Cint, nb::Cint, nnzb::Cint, alpha::Ref{Cfloat},
                                       descrA::cusparseMatDescr_t,
                                       bsrSortedValA::CuPtr{Cfloat},
                                       bsrSortedMaskPtrA::CuPtr{Cint},
                                       bsrSortedRowPtrA::CuPtr{Cint},
                                       bsrSortedEndPtrA::CuPtr{Cint},
                                       bsrSortedColIndA::CuPtr{Cint}, blockDim::Cint,
                                       x::CuPtr{Cfloat}, beta::Ref{Cfloat},
                                       y::CuPtr{Cfloat})::cusparseStatus_t
end

@checked function cusparseDbsrxmv(handle, dirA, transA, sizeOfMask, mb, nb, nnzb, alpha,
                                  descrA, bsrSortedValA, bsrSortedMaskPtrA,
                                  bsrSortedRowPtrA, bsrSortedEndPtrA, bsrSortedColIndA,
                                  blockDim, x, beta, y)
    initialize_context()
    @ccall libcusparse.cusparseDbsrxmv(handle::cusparseHandle_t, dirA::cusparseDirection_t,
                                       transA::cusparseOperation_t, sizeOfMask::Cint,
                                       mb::Cint, nb::Cint, nnzb::Cint, alpha::Ref{Cdouble},
                                       descrA::cusparseMatDescr_t,
                                       bsrSortedValA::CuPtr{Cdouble},
                                       bsrSortedMaskPtrA::CuPtr{Cint},
                                       bsrSortedRowPtrA::CuPtr{Cint},
                                       bsrSortedEndPtrA::CuPtr{Cint},
                                       bsrSortedColIndA::CuPtr{Cint}, blockDim::Cint,
                                       x::CuPtr{Cdouble}, beta::Ref{Cdouble},
                                       y::CuPtr{Cdouble})::cusparseStatus_t
end

@checked function cusparseCbsrxmv(handle, dirA, transA, sizeOfMask, mb, nb, nnzb, alpha,
                                  descrA, bsrSortedValA, bsrSortedMaskPtrA,
                                  bsrSortedRowPtrA, bsrSortedEndPtrA, bsrSortedColIndA,
                                  blockDim, x, beta, y)
    initialize_context()
    @ccall libcusparse.cusparseCbsrxmv(handle::cusparseHandle_t, dirA::cusparseDirection_t,
                                       transA::cusparseOperation_t, sizeOfMask::Cint,
                                       mb::Cint, nb::Cint, nnzb::Cint,
                                       alpha::Ref{cuComplex}, descrA::cusparseMatDescr_t,
                                       bsrSortedValA::CuPtr{cuComplex},
                                       bsrSortedMaskPtrA::CuPtr{Cint},
                                       bsrSortedRowPtrA::CuPtr{Cint},
                                       bsrSortedEndPtrA::CuPtr{Cint},
                                       bsrSortedColIndA::CuPtr{Cint}, blockDim::Cint,
                                       x::CuPtr{cuComplex}, beta::Ref{cuComplex},
                                       y::CuPtr{cuComplex})::cusparseStatus_t
end

@checked function cusparseZbsrxmv(handle, dirA, transA, sizeOfMask, mb, nb, nnzb, alpha,
                                  descrA, bsrSortedValA, bsrSortedMaskPtrA,
                                  bsrSortedRowPtrA, bsrSortedEndPtrA, bsrSortedColIndA,
                                  blockDim, x, beta, y)
    initialize_context()
    @ccall libcusparse.cusparseZbsrxmv(handle::cusparseHandle_t, dirA::cusparseDirection_t,
                                       transA::cusparseOperation_t, sizeOfMask::Cint,
                                       mb::Cint, nb::Cint, nnzb::Cint,
                                       alpha::Ref{cuDoubleComplex},
                                       descrA::cusparseMatDescr_t,
                                       bsrSortedValA::CuPtr{cuDoubleComplex},
                                       bsrSortedMaskPtrA::CuPtr{Cint},
                                       bsrSortedRowPtrA::CuPtr{Cint},
                                       bsrSortedEndPtrA::CuPtr{Cint},
                                       bsrSortedColIndA::CuPtr{Cint}, blockDim::Cint,
                                       x::CuPtr{cuDoubleComplex},
                                       beta::Ref{cuDoubleComplex},
                                       y::CuPtr{cuDoubleComplex})::cusparseStatus_t
end

@checked function cusparseXcsrsv2_zeroPivot(handle, info, position)
    initialize_context()
    @ccall libcusparse.cusparseXcsrsv2_zeroPivot(handle::cusparseHandle_t,
                                                 info::csrsv2Info_t,
                                                 position::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseScsrsv2_bufferSize(handle, transA, m, nnz, descrA, csrSortedValA,
                                             csrSortedRowPtrA, csrSortedColIndA, info,
                                             pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseScsrsv2_bufferSize(handle::cusparseHandle_t,
                                                  transA::cusparseOperation_t, m::Cint,
                                                  nnz::Cint, descrA::cusparseMatDescr_t,
                                                  csrSortedValA::CuPtr{Cfloat},
                                                  csrSortedRowPtrA::CuPtr{Cint},
                                                  csrSortedColIndA::CuPtr{Cint},
                                                  info::csrsv2Info_t,
                                                  pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseDcsrsv2_bufferSize(handle, transA, m, nnz, descrA, csrSortedValA,
                                             csrSortedRowPtrA, csrSortedColIndA, info,
                                             pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseDcsrsv2_bufferSize(handle::cusparseHandle_t,
                                                  transA::cusparseOperation_t, m::Cint,
                                                  nnz::Cint, descrA::cusparseMatDescr_t,
                                                  csrSortedValA::CuPtr{Cdouble},
                                                  csrSortedRowPtrA::CuPtr{Cint},
                                                  csrSortedColIndA::CuPtr{Cint},
                                                  info::csrsv2Info_t,
                                                  pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseCcsrsv2_bufferSize(handle, transA, m, nnz, descrA, csrSortedValA,
                                             csrSortedRowPtrA, csrSortedColIndA, info,
                                             pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseCcsrsv2_bufferSize(handle::cusparseHandle_t,
                                                  transA::cusparseOperation_t, m::Cint,
                                                  nnz::Cint, descrA::cusparseMatDescr_t,
                                                  csrSortedValA::CuPtr{cuComplex},
                                                  csrSortedRowPtrA::CuPtr{Cint},
                                                  csrSortedColIndA::CuPtr{Cint},
                                                  info::csrsv2Info_t,
                                                  pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseZcsrsv2_bufferSize(handle, transA, m, nnz, descrA, csrSortedValA,
                                             csrSortedRowPtrA, csrSortedColIndA, info,
                                             pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseZcsrsv2_bufferSize(handle::cusparseHandle_t,
                                                  transA::cusparseOperation_t, m::Cint,
                                                  nnz::Cint, descrA::cusparseMatDescr_t,
                                                  csrSortedValA::CuPtr{cuDoubleComplex},
                                                  csrSortedRowPtrA::CuPtr{Cint},
                                                  csrSortedColIndA::CuPtr{Cint},
                                                  info::csrsv2Info_t,
                                                  pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseScsrsv2_bufferSizeExt(handle, transA, m, nnz, descrA,
                                                csrSortedValA, csrSortedRowPtrA,
                                                csrSortedColIndA, info, pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseScsrsv2_bufferSizeExt(handle::cusparseHandle_t,
                                                     transA::cusparseOperation_t, m::Cint,
                                                     nnz::Cint, descrA::cusparseMatDescr_t,
                                                     csrSortedValA::CuPtr{Cfloat},
                                                     csrSortedRowPtrA::CuPtr{Cint},
                                                     csrSortedColIndA::CuPtr{Cint},
                                                     info::csrsv2Info_t,
                                                     pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseDcsrsv2_bufferSizeExt(handle, transA, m, nnz, descrA,
                                                csrSortedValA, csrSortedRowPtrA,
                                                csrSortedColIndA, info, pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseDcsrsv2_bufferSizeExt(handle::cusparseHandle_t,
                                                     transA::cusparseOperation_t, m::Cint,
                                                     nnz::Cint, descrA::cusparseMatDescr_t,
                                                     csrSortedValA::CuPtr{Cdouble},
                                                     csrSortedRowPtrA::CuPtr{Cint},
                                                     csrSortedColIndA::CuPtr{Cint},
                                                     info::csrsv2Info_t,
                                                     pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseCcsrsv2_bufferSizeExt(handle, transA, m, nnz, descrA,
                                                csrSortedValA, csrSortedRowPtrA,
                                                csrSortedColIndA, info, pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseCcsrsv2_bufferSizeExt(handle::cusparseHandle_t,
                                                     transA::cusparseOperation_t, m::Cint,
                                                     nnz::Cint, descrA::cusparseMatDescr_t,
                                                     csrSortedValA::CuPtr{cuComplex},
                                                     csrSortedRowPtrA::CuPtr{Cint},
                                                     csrSortedColIndA::CuPtr{Cint},
                                                     info::csrsv2Info_t,
                                                     pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseZcsrsv2_bufferSizeExt(handle, transA, m, nnz, descrA,
                                                csrSortedValA, csrSortedRowPtrA,
                                                csrSortedColIndA, info, pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseZcsrsv2_bufferSizeExt(handle::cusparseHandle_t,
                                                     transA::cusparseOperation_t, m::Cint,
                                                     nnz::Cint, descrA::cusparseMatDescr_t,
                                                     csrSortedValA::CuPtr{cuDoubleComplex},
                                                     csrSortedRowPtrA::CuPtr{Cint},
                                                     csrSortedColIndA::CuPtr{Cint},
                                                     info::csrsv2Info_t,
                                                     pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseScsrsv2_analysis(handle, transA, m, nnz, descrA, csrSortedValA,
                                           csrSortedRowPtrA, csrSortedColIndA, info, policy,
                                           pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseScsrsv2_analysis(handle::cusparseHandle_t,
                                                transA::cusparseOperation_t, m::Cint,
                                                nnz::Cint, descrA::cusparseMatDescr_t,
                                                csrSortedValA::CuPtr{Cfloat},
                                                csrSortedRowPtrA::CuPtr{Cint},
                                                csrSortedColIndA::CuPtr{Cint},
                                                info::csrsv2Info_t,
                                                policy::cusparseSolvePolicy_t,
                                                pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDcsrsv2_analysis(handle, transA, m, nnz, descrA, csrSortedValA,
                                           csrSortedRowPtrA, csrSortedColIndA, info, policy,
                                           pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDcsrsv2_analysis(handle::cusparseHandle_t,
                                                transA::cusparseOperation_t, m::Cint,
                                                nnz::Cint, descrA::cusparseMatDescr_t,
                                                csrSortedValA::CuPtr{Cdouble},
                                                csrSortedRowPtrA::CuPtr{Cint},
                                                csrSortedColIndA::CuPtr{Cint},
                                                info::csrsv2Info_t,
                                                policy::cusparseSolvePolicy_t,
                                                pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCcsrsv2_analysis(handle, transA, m, nnz, descrA, csrSortedValA,
                                           csrSortedRowPtrA, csrSortedColIndA, info, policy,
                                           pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCcsrsv2_analysis(handle::cusparseHandle_t,
                                                transA::cusparseOperation_t, m::Cint,
                                                nnz::Cint, descrA::cusparseMatDescr_t,
                                                csrSortedValA::CuPtr{cuComplex},
                                                csrSortedRowPtrA::CuPtr{Cint},
                                                csrSortedColIndA::CuPtr{Cint},
                                                info::csrsv2Info_t,
                                                policy::cusparseSolvePolicy_t,
                                                pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZcsrsv2_analysis(handle, transA, m, nnz, descrA, csrSortedValA,
                                           csrSortedRowPtrA, csrSortedColIndA, info, policy,
                                           pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZcsrsv2_analysis(handle::cusparseHandle_t,
                                                transA::cusparseOperation_t, m::Cint,
                                                nnz::Cint, descrA::cusparseMatDescr_t,
                                                csrSortedValA::CuPtr{cuDoubleComplex},
                                                csrSortedRowPtrA::CuPtr{Cint},
                                                csrSortedColIndA::CuPtr{Cint},
                                                info::csrsv2Info_t,
                                                policy::cusparseSolvePolicy_t,
                                                pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseScsrsv2_solve(handle, transA, m, nnz, alpha, descrA,
                                        csrSortedValA, csrSortedRowPtrA, csrSortedColIndA,
                                        info, f, x, policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseScsrsv2_solve(handle::cusparseHandle_t,
                                             transA::cusparseOperation_t, m::Cint,
                                             nnz::Cint, alpha::Ref{Cfloat},
                                             descrA::cusparseMatDescr_t,
                                             csrSortedValA::CuPtr{Cfloat},
                                             csrSortedRowPtrA::CuPtr{Cint},
                                             csrSortedColIndA::CuPtr{Cint},
                                             info::csrsv2Info_t, f::CuPtr{Cfloat},
                                             x::CuPtr{Cfloat},
                                             policy::cusparseSolvePolicy_t,
                                             pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDcsrsv2_solve(handle, transA, m, nnz, alpha, descrA,
                                        csrSortedValA, csrSortedRowPtrA, csrSortedColIndA,
                                        info, f, x, policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDcsrsv2_solve(handle::cusparseHandle_t,
                                             transA::cusparseOperation_t, m::Cint,
                                             nnz::Cint, alpha::Ref{Cdouble},
                                             descrA::cusparseMatDescr_t,
                                             csrSortedValA::CuPtr{Cdouble},
                                             csrSortedRowPtrA::CuPtr{Cint},
                                             csrSortedColIndA::CuPtr{Cint},
                                             info::csrsv2Info_t, f::CuPtr{Cdouble},
                                             x::CuPtr{Cdouble},
                                             policy::cusparseSolvePolicy_t,
                                             pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCcsrsv2_solve(handle, transA, m, nnz, alpha, descrA,
                                        csrSortedValA, csrSortedRowPtrA, csrSortedColIndA,
                                        info, f, x, policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCcsrsv2_solve(handle::cusparseHandle_t,
                                             transA::cusparseOperation_t, m::Cint,
                                             nnz::Cint, alpha::Ref{cuComplex},
                                             descrA::cusparseMatDescr_t,
                                             csrSortedValA::CuPtr{cuComplex},
                                             csrSortedRowPtrA::CuPtr{Cint},
                                             csrSortedColIndA::CuPtr{Cint},
                                             info::csrsv2Info_t, f::CuPtr{cuComplex},
                                             x::CuPtr{cuComplex},
                                             policy::cusparseSolvePolicy_t,
                                             pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZcsrsv2_solve(handle, transA, m, nnz, alpha, descrA,
                                        csrSortedValA, csrSortedRowPtrA, csrSortedColIndA,
                                        info, f, x, policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZcsrsv2_solve(handle::cusparseHandle_t,
                                             transA::cusparseOperation_t, m::Cint,
                                             nnz::Cint, alpha::Ref{cuDoubleComplex},
                                             descrA::cusparseMatDescr_t,
                                             csrSortedValA::CuPtr{cuDoubleComplex},
                                             csrSortedRowPtrA::CuPtr{Cint},
                                             csrSortedColIndA::CuPtr{Cint},
                                             info::csrsv2Info_t, f::CuPtr{cuDoubleComplex},
                                             x::CuPtr{cuDoubleComplex},
                                             policy::cusparseSolvePolicy_t,
                                             pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseXbsrsv2_zeroPivot(handle, info, position)
    initialize_context()
    @ccall libcusparse.cusparseXbsrsv2_zeroPivot(handle::cusparseHandle_t,
                                                 info::bsrsv2Info_t,
                                                 position::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseSbsrsv2_bufferSize(handle, dirA, transA, mb, nnzb, descrA,
                                             bsrSortedValA, bsrSortedRowPtrA,
                                             bsrSortedColIndA, blockDim, info,
                                             pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseSbsrsv2_bufferSize(handle::cusparseHandle_t,
                                                  dirA::cusparseDirection_t,
                                                  transA::cusparseOperation_t, mb::Cint,
                                                  nnzb::Cint, descrA::cusparseMatDescr_t,
                                                  bsrSortedValA::CuPtr{Cfloat},
                                                  bsrSortedRowPtrA::CuPtr{Cint},
                                                  bsrSortedColIndA::CuPtr{Cint},
                                                  blockDim::Cint, info::bsrsv2Info_t,
                                                  pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseDbsrsv2_bufferSize(handle, dirA, transA, mb, nnzb, descrA,
                                             bsrSortedValA, bsrSortedRowPtrA,
                                             bsrSortedColIndA, blockDim, info,
                                             pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseDbsrsv2_bufferSize(handle::cusparseHandle_t,
                                                  dirA::cusparseDirection_t,
                                                  transA::cusparseOperation_t, mb::Cint,
                                                  nnzb::Cint, descrA::cusparseMatDescr_t,
                                                  bsrSortedValA::CuPtr{Cdouble},
                                                  bsrSortedRowPtrA::CuPtr{Cint},
                                                  bsrSortedColIndA::CuPtr{Cint},
                                                  blockDim::Cint, info::bsrsv2Info_t,
                                                  pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseCbsrsv2_bufferSize(handle, dirA, transA, mb, nnzb, descrA,
                                             bsrSortedValA, bsrSortedRowPtrA,
                                             bsrSortedColIndA, blockDim, info,
                                             pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseCbsrsv2_bufferSize(handle::cusparseHandle_t,
                                                  dirA::cusparseDirection_t,
                                                  transA::cusparseOperation_t, mb::Cint,
                                                  nnzb::Cint, descrA::cusparseMatDescr_t,
                                                  bsrSortedValA::CuPtr{cuComplex},
                                                  bsrSortedRowPtrA::CuPtr{Cint},
                                                  bsrSortedColIndA::CuPtr{Cint},
                                                  blockDim::Cint, info::bsrsv2Info_t,
                                                  pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseZbsrsv2_bufferSize(handle, dirA, transA, mb, nnzb, descrA,
                                             bsrSortedValA, bsrSortedRowPtrA,
                                             bsrSortedColIndA, blockDim, info,
                                             pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseZbsrsv2_bufferSize(handle::cusparseHandle_t,
                                                  dirA::cusparseDirection_t,
                                                  transA::cusparseOperation_t, mb::Cint,
                                                  nnzb::Cint, descrA::cusparseMatDescr_t,
                                                  bsrSortedValA::CuPtr{cuDoubleComplex},
                                                  bsrSortedRowPtrA::CuPtr{Cint},
                                                  bsrSortedColIndA::CuPtr{Cint},
                                                  blockDim::Cint, info::bsrsv2Info_t,
                                                  pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseSbsrsv2_bufferSizeExt(handle, dirA, transA, mb, nnzb, descrA,
                                                bsrSortedValA, bsrSortedRowPtrA,
                                                bsrSortedColIndA, blockSize, info,
                                                pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseSbsrsv2_bufferSizeExt(handle::cusparseHandle_t,
                                                     dirA::cusparseDirection_t,
                                                     transA::cusparseOperation_t, mb::Cint,
                                                     nnzb::Cint, descrA::cusparseMatDescr_t,
                                                     bsrSortedValA::CuPtr{Cfloat},
                                                     bsrSortedRowPtrA::CuPtr{Cint},
                                                     bsrSortedColIndA::CuPtr{Cint},
                                                     blockSize::Cint, info::bsrsv2Info_t,
                                                     pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseDbsrsv2_bufferSizeExt(handle, dirA, transA, mb, nnzb, descrA,
                                                bsrSortedValA, bsrSortedRowPtrA,
                                                bsrSortedColIndA, blockSize, info,
                                                pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseDbsrsv2_bufferSizeExt(handle::cusparseHandle_t,
                                                     dirA::cusparseDirection_t,
                                                     transA::cusparseOperation_t, mb::Cint,
                                                     nnzb::Cint, descrA::cusparseMatDescr_t,
                                                     bsrSortedValA::CuPtr{Cdouble},
                                                     bsrSortedRowPtrA::CuPtr{Cint},
                                                     bsrSortedColIndA::CuPtr{Cint},
                                                     blockSize::Cint, info::bsrsv2Info_t,
                                                     pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseCbsrsv2_bufferSizeExt(handle, dirA, transA, mb, nnzb, descrA,
                                                bsrSortedValA, bsrSortedRowPtrA,
                                                bsrSortedColIndA, blockSize, info,
                                                pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseCbsrsv2_bufferSizeExt(handle::cusparseHandle_t,
                                                     dirA::cusparseDirection_t,
                                                     transA::cusparseOperation_t, mb::Cint,
                                                     nnzb::Cint, descrA::cusparseMatDescr_t,
                                                     bsrSortedValA::CuPtr{cuComplex},
                                                     bsrSortedRowPtrA::CuPtr{Cint},
                                                     bsrSortedColIndA::CuPtr{Cint},
                                                     blockSize::Cint, info::bsrsv2Info_t,
                                                     pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseZbsrsv2_bufferSizeExt(handle, dirA, transA, mb, nnzb, descrA,
                                                bsrSortedValA, bsrSortedRowPtrA,
                                                bsrSortedColIndA, blockSize, info,
                                                pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseZbsrsv2_bufferSizeExt(handle::cusparseHandle_t,
                                                     dirA::cusparseDirection_t,
                                                     transA::cusparseOperation_t, mb::Cint,
                                                     nnzb::Cint, descrA::cusparseMatDescr_t,
                                                     bsrSortedValA::CuPtr{cuDoubleComplex},
                                                     bsrSortedRowPtrA::CuPtr{Cint},
                                                     bsrSortedColIndA::CuPtr{Cint},
                                                     blockSize::Cint, info::bsrsv2Info_t,
                                                     pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseSbsrsv2_analysis(handle, dirA, transA, mb, nnzb, descrA,
                                           bsrSortedValA, bsrSortedRowPtrA,
                                           bsrSortedColIndA, blockDim, info, policy,
                                           pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSbsrsv2_analysis(handle::cusparseHandle_t,
                                                dirA::cusparseDirection_t,
                                                transA::cusparseOperation_t, mb::Cint,
                                                nnzb::Cint, descrA::cusparseMatDescr_t,
                                                bsrSortedValA::CuPtr{Cfloat},
                                                bsrSortedRowPtrA::CuPtr{Cint},
                                                bsrSortedColIndA::CuPtr{Cint},
                                                blockDim::Cint, info::bsrsv2Info_t,
                                                policy::cusparseSolvePolicy_t,
                                                pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDbsrsv2_analysis(handle, dirA, transA, mb, nnzb, descrA,
                                           bsrSortedValA, bsrSortedRowPtrA,
                                           bsrSortedColIndA, blockDim, info, policy,
                                           pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDbsrsv2_analysis(handle::cusparseHandle_t,
                                                dirA::cusparseDirection_t,
                                                transA::cusparseOperation_t, mb::Cint,
                                                nnzb::Cint, descrA::cusparseMatDescr_t,
                                                bsrSortedValA::CuPtr{Cdouble},
                                                bsrSortedRowPtrA::CuPtr{Cint},
                                                bsrSortedColIndA::CuPtr{Cint},
                                                blockDim::Cint, info::bsrsv2Info_t,
                                                policy::cusparseSolvePolicy_t,
                                                pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCbsrsv2_analysis(handle, dirA, transA, mb, nnzb, descrA,
                                           bsrSortedValA, bsrSortedRowPtrA,
                                           bsrSortedColIndA, blockDim, info, policy,
                                           pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCbsrsv2_analysis(handle::cusparseHandle_t,
                                                dirA::cusparseDirection_t,
                                                transA::cusparseOperation_t, mb::Cint,
                                                nnzb::Cint, descrA::cusparseMatDescr_t,
                                                bsrSortedValA::CuPtr{cuComplex},
                                                bsrSortedRowPtrA::CuPtr{Cint},
                                                bsrSortedColIndA::CuPtr{Cint},
                                                blockDim::Cint, info::bsrsv2Info_t,
                                                policy::cusparseSolvePolicy_t,
                                                pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZbsrsv2_analysis(handle, dirA, transA, mb, nnzb, descrA,
                                           bsrSortedValA, bsrSortedRowPtrA,
                                           bsrSortedColIndA, blockDim, info, policy,
                                           pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZbsrsv2_analysis(handle::cusparseHandle_t,
                                                dirA::cusparseDirection_t,
                                                transA::cusparseOperation_t, mb::Cint,
                                                nnzb::Cint, descrA::cusparseMatDescr_t,
                                                bsrSortedValA::CuPtr{cuDoubleComplex},
                                                bsrSortedRowPtrA::CuPtr{Cint},
                                                bsrSortedColIndA::CuPtr{Cint},
                                                blockDim::Cint, info::bsrsv2Info_t,
                                                policy::cusparseSolvePolicy_t,
                                                pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSbsrsv2_solve(handle, dirA, transA, mb, nnzb, alpha, descrA,
                                        bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA,
                                        blockDim, info, f, x, policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSbsrsv2_solve(handle::cusparseHandle_t,
                                             dirA::cusparseDirection_t,
                                             transA::cusparseOperation_t, mb::Cint,
                                             nnzb::Cint, alpha::Ref{Cfloat},
                                             descrA::cusparseMatDescr_t,
                                             bsrSortedValA::CuPtr{Cfloat},
                                             bsrSortedRowPtrA::CuPtr{Cint},
                                             bsrSortedColIndA::CuPtr{Cint}, blockDim::Cint,
                                             info::bsrsv2Info_t, f::CuPtr{Cfloat},
                                             x::CuPtr{Cfloat},
                                             policy::cusparseSolvePolicy_t,
                                             pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDbsrsv2_solve(handle, dirA, transA, mb, nnzb, alpha, descrA,
                                        bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA,
                                        blockDim, info, f, x, policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDbsrsv2_solve(handle::cusparseHandle_t,
                                             dirA::cusparseDirection_t,
                                             transA::cusparseOperation_t, mb::Cint,
                                             nnzb::Cint, alpha::Ref{Cdouble},
                                             descrA::cusparseMatDescr_t,
                                             bsrSortedValA::CuPtr{Cdouble},
                                             bsrSortedRowPtrA::CuPtr{Cint},
                                             bsrSortedColIndA::CuPtr{Cint}, blockDim::Cint,
                                             info::bsrsv2Info_t, f::CuPtr{Cdouble},
                                             x::CuPtr{Cdouble},
                                             policy::cusparseSolvePolicy_t,
                                             pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCbsrsv2_solve(handle, dirA, transA, mb, nnzb, alpha, descrA,
                                        bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA,
                                        blockDim, info, f, x, policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCbsrsv2_solve(handle::cusparseHandle_t,
                                             dirA::cusparseDirection_t,
                                             transA::cusparseOperation_t, mb::Cint,
                                             nnzb::Cint, alpha::Ref{cuComplex},
                                             descrA::cusparseMatDescr_t,
                                             bsrSortedValA::CuPtr{cuComplex},
                                             bsrSortedRowPtrA::CuPtr{Cint},
                                             bsrSortedColIndA::CuPtr{Cint}, blockDim::Cint,
                                             info::bsrsv2Info_t, f::CuPtr{cuComplex},
                                             x::CuPtr{cuComplex},
                                             policy::cusparseSolvePolicy_t,
                                             pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZbsrsv2_solve(handle, dirA, transA, mb, nnzb, alpha, descrA,
                                        bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA,
                                        blockDim, info, f, x, policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZbsrsv2_solve(handle::cusparseHandle_t,
                                             dirA::cusparseDirection_t,
                                             transA::cusparseOperation_t, mb::Cint,
                                             nnzb::Cint, alpha::Ref{cuDoubleComplex},
                                             descrA::cusparseMatDescr_t,
                                             bsrSortedValA::CuPtr{cuDoubleComplex},
                                             bsrSortedRowPtrA::CuPtr{Cint},
                                             bsrSortedColIndA::CuPtr{Cint}, blockDim::Cint,
                                             info::bsrsv2Info_t, f::CuPtr{cuDoubleComplex},
                                             x::CuPtr{cuDoubleComplex},
                                             policy::cusparseSolvePolicy_t,
                                             pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSbsrmm(handle, dirA, transA, transB, mb, n, kb, nnzb, alpha,
                                 descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA,
                                 blockSize, B, ldb, beta, C, ldc)
    initialize_context()
    @ccall libcusparse.cusparseSbsrmm(handle::cusparseHandle_t, dirA::cusparseDirection_t,
                                      transA::cusparseOperation_t,
                                      transB::cusparseOperation_t, mb::Cint, n::Cint,
                                      kb::Cint, nnzb::Cint, alpha::Ref{Cfloat},
                                      descrA::cusparseMatDescr_t,
                                      bsrSortedValA::CuPtr{Cfloat},
                                      bsrSortedRowPtrA::CuPtr{Cint},
                                      bsrSortedColIndA::CuPtr{Cint}, blockSize::Cint,
                                      B::CuPtr{Cfloat}, ldb::Cint, beta::Ref{Cfloat},
                                      C::CuPtr{Cfloat}, ldc::Cint)::cusparseStatus_t
end

@checked function cusparseDbsrmm(handle, dirA, transA, transB, mb, n, kb, nnzb, alpha,
                                 descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA,
                                 blockSize, B, ldb, beta, C, ldc)
    initialize_context()
    @ccall libcusparse.cusparseDbsrmm(handle::cusparseHandle_t, dirA::cusparseDirection_t,
                                      transA::cusparseOperation_t,
                                      transB::cusparseOperation_t, mb::Cint, n::Cint,
                                      kb::Cint, nnzb::Cint, alpha::Ref{Cdouble},
                                      descrA::cusparseMatDescr_t,
                                      bsrSortedValA::CuPtr{Cdouble},
                                      bsrSortedRowPtrA::CuPtr{Cint},
                                      bsrSortedColIndA::CuPtr{Cint}, blockSize::Cint,
                                      B::CuPtr{Cdouble}, ldb::Cint, beta::Ref{Cdouble},
                                      C::CuPtr{Cdouble}, ldc::Cint)::cusparseStatus_t
end

@checked function cusparseCbsrmm(handle, dirA, transA, transB, mb, n, kb, nnzb, alpha,
                                 descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA,
                                 blockSize, B, ldb, beta, C, ldc)
    initialize_context()
    @ccall libcusparse.cusparseCbsrmm(handle::cusparseHandle_t, dirA::cusparseDirection_t,
                                      transA::cusparseOperation_t,
                                      transB::cusparseOperation_t, mb::Cint, n::Cint,
                                      kb::Cint, nnzb::Cint, alpha::Ref{cuComplex},
                                      descrA::cusparseMatDescr_t,
                                      bsrSortedValA::CuPtr{cuComplex},
                                      bsrSortedRowPtrA::CuPtr{Cint},
                                      bsrSortedColIndA::CuPtr{Cint}, blockSize::Cint,
                                      B::CuPtr{cuComplex}, ldb::Cint, beta::Ref{cuComplex},
                                      C::CuPtr{cuComplex}, ldc::Cint)::cusparseStatus_t
end

@checked function cusparseZbsrmm(handle, dirA, transA, transB, mb, n, kb, nnzb, alpha,
                                 descrA, bsrSortedValA, bsrSortedRowPtrA, bsrSortedColIndA,
                                 blockSize, B, ldb, beta, C, ldc)
    initialize_context()
    @ccall libcusparse.cusparseZbsrmm(handle::cusparseHandle_t, dirA::cusparseDirection_t,
                                      transA::cusparseOperation_t,
                                      transB::cusparseOperation_t, mb::Cint, n::Cint,
                                      kb::Cint, nnzb::Cint, alpha::Ref{cuDoubleComplex},
                                      descrA::cusparseMatDescr_t,
                                      bsrSortedValA::CuPtr{cuDoubleComplex},
                                      bsrSortedRowPtrA::CuPtr{Cint},
                                      bsrSortedColIndA::CuPtr{Cint}, blockSize::Cint,
                                      B::CuPtr{cuDoubleComplex}, ldb::Cint,
                                      beta::Ref{cuDoubleComplex}, C::CuPtr{cuDoubleComplex},
                                      ldc::Cint)::cusparseStatus_t
end

@checked function cusparseSgemmi(handle, m, n, k, nnz, alpha, A, lda, cscValB, cscColPtrB,
                                 cscRowIndB, beta, C, ldc)
    initialize_context()
    @ccall libcusparse.cusparseSgemmi(handle::cusparseHandle_t, m::Cint, n::Cint, k::Cint,
                                      nnz::Cint, alpha::Ref{Cfloat}, A::CuPtr{Cfloat},
                                      lda::Cint, cscValB::CuPtr{Cfloat},
                                      cscColPtrB::CuPtr{Cint}, cscRowIndB::CuPtr{Cint},
                                      beta::Ref{Cfloat}, C::CuPtr{Cfloat},
                                      ldc::Cint)::cusparseStatus_t
end

@checked function cusparseDgemmi(handle, m, n, k, nnz, alpha, A, lda, cscValB, cscColPtrB,
                                 cscRowIndB, beta, C, ldc)
    initialize_context()
    @ccall libcusparse.cusparseDgemmi(handle::cusparseHandle_t, m::Cint, n::Cint, k::Cint,
                                      nnz::Cint, alpha::Ref{Cdouble}, A::CuPtr{Cdouble},
                                      lda::Cint, cscValB::CuPtr{Cdouble},
                                      cscColPtrB::CuPtr{Cint}, cscRowIndB::CuPtr{Cint},
                                      beta::Ref{Cdouble}, C::CuPtr{Cdouble},
                                      ldc::Cint)::cusparseStatus_t
end

@checked function cusparseCgemmi(handle, m, n, k, nnz, alpha, A, lda, cscValB, cscColPtrB,
                                 cscRowIndB, beta, C, ldc)
    initialize_context()
    @ccall libcusparse.cusparseCgemmi(handle::cusparseHandle_t, m::Cint, n::Cint, k::Cint,
                                      nnz::Cint, alpha::Ref{cuComplex}, A::CuPtr{cuComplex},
                                      lda::Cint, cscValB::CuPtr{cuComplex},
                                      cscColPtrB::CuPtr{Cint}, cscRowIndB::CuPtr{Cint},
                                      beta::Ref{cuComplex}, C::CuPtr{cuComplex},
                                      ldc::Cint)::cusparseStatus_t
end

@checked function cusparseZgemmi(handle, m, n, k, nnz, alpha, A, lda, cscValB, cscColPtrB,
                                 cscRowIndB, beta, C, ldc)
    initialize_context()
    @ccall libcusparse.cusparseZgemmi(handle::cusparseHandle_t, m::Cint, n::Cint, k::Cint,
                                      nnz::Cint, alpha::Ref{cuDoubleComplex},
                                      A::CuPtr{cuDoubleComplex}, lda::Cint,
                                      cscValB::CuPtr{cuDoubleComplex},
                                      cscColPtrB::CuPtr{Cint}, cscRowIndB::CuPtr{Cint},
                                      beta::Ref{cuDoubleComplex}, C::CuPtr{cuDoubleComplex},
                                      ldc::Cint)::cusparseStatus_t
end

@checked function cusparseCreateCsrsm2Info(info)
    initialize_context()
    @ccall libcusparse.cusparseCreateCsrsm2Info(info::Ptr{csrsm2Info_t})::cusparseStatus_t
end

@checked function cusparseDestroyCsrsm2Info(info)
    initialize_context()
    @ccall libcusparse.cusparseDestroyCsrsm2Info(info::csrsm2Info_t)::cusparseStatus_t
end

@checked function cusparseXcsrsm2_zeroPivot(handle, info, position)
    initialize_context()
    @ccall libcusparse.cusparseXcsrsm2_zeroPivot(handle::cusparseHandle_t,
                                                 info::csrsm2Info_t,
                                                 position::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseScsrsm2_bufferSizeExt(handle, algo, transA, transB, m, nrhs, nnz,
                                                alpha, descrA, csrSortedValA,
                                                csrSortedRowPtrA, csrSortedColIndA, B, ldb,
                                                info, policy, pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseScsrsm2_bufferSizeExt(handle::cusparseHandle_t, algo::Cint,
                                                     transA::cusparseOperation_t,
                                                     transB::cusparseOperation_t, m::Cint,
                                                     nrhs::Cint, nnz::Cint,
                                                     alpha::Ref{Cfloat},
                                                     descrA::cusparseMatDescr_t,
                                                     csrSortedValA::CuPtr{Cfloat},
                                                     csrSortedRowPtrA::CuPtr{Cint},
                                                     csrSortedColIndA::CuPtr{Cint},
                                                     B::CuPtr{Cfloat}, ldb::Cint,
                                                     info::csrsm2Info_t,
                                                     policy::cusparseSolvePolicy_t,
                                                     pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseDcsrsm2_bufferSizeExt(handle, algo, transA, transB, m, nrhs, nnz,
                                                alpha, descrA, csrSortedValA,
                                                csrSortedRowPtrA, csrSortedColIndA, B, ldb,
                                                info, policy, pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseDcsrsm2_bufferSizeExt(handle::cusparseHandle_t, algo::Cint,
                                                     transA::cusparseOperation_t,
                                                     transB::cusparseOperation_t, m::Cint,
                                                     nrhs::Cint, nnz::Cint,
                                                     alpha::Ref{Cdouble},
                                                     descrA::cusparseMatDescr_t,
                                                     csrSortedValA::CuPtr{Cdouble},
                                                     csrSortedRowPtrA::CuPtr{Cint},
                                                     csrSortedColIndA::CuPtr{Cint},
                                                     B::CuPtr{Cdouble}, ldb::Cint,
                                                     info::csrsm2Info_t,
                                                     policy::cusparseSolvePolicy_t,
                                                     pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseCcsrsm2_bufferSizeExt(handle, algo, transA, transB, m, nrhs, nnz,
                                                alpha, descrA, csrSortedValA,
                                                csrSortedRowPtrA, csrSortedColIndA, B, ldb,
                                                info, policy, pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseCcsrsm2_bufferSizeExt(handle::cusparseHandle_t, algo::Cint,
                                                     transA::cusparseOperation_t,
                                                     transB::cusparseOperation_t, m::Cint,
                                                     nrhs::Cint, nnz::Cint,
                                                     alpha::Ref{cuComplex},
                                                     descrA::cusparseMatDescr_t,
                                                     csrSortedValA::CuPtr{cuComplex},
                                                     csrSortedRowPtrA::CuPtr{Cint},
                                                     csrSortedColIndA::CuPtr{Cint},
                                                     B::CuPtr{cuComplex}, ldb::Cint,
                                                     info::csrsm2Info_t,
                                                     policy::cusparseSolvePolicy_t,
                                                     pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseZcsrsm2_bufferSizeExt(handle, algo, transA, transB, m, nrhs, nnz,
                                                alpha, descrA, csrSortedValA,
                                                csrSortedRowPtrA, csrSortedColIndA, B, ldb,
                                                info, policy, pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseZcsrsm2_bufferSizeExt(handle::cusparseHandle_t, algo::Cint,
                                                     transA::cusparseOperation_t,
                                                     transB::cusparseOperation_t, m::Cint,
                                                     nrhs::Cint, nnz::Cint,
                                                     alpha::Ref{cuDoubleComplex},
                                                     descrA::cusparseMatDescr_t,
                                                     csrSortedValA::CuPtr{cuDoubleComplex},
                                                     csrSortedRowPtrA::CuPtr{Cint},
                                                     csrSortedColIndA::CuPtr{Cint},
                                                     B::CuPtr{cuDoubleComplex}, ldb::Cint,
                                                     info::csrsm2Info_t,
                                                     policy::cusparseSolvePolicy_t,
                                                     pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseScsrsm2_analysis(handle, algo, transA, transB, m, nrhs, nnz,
                                           alpha, descrA, csrSortedValA, csrSortedRowPtrA,
                                           csrSortedColIndA, B, ldb, info, policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseScsrsm2_analysis(handle::cusparseHandle_t, algo::Cint,
                                                transA::cusparseOperation_t,
                                                transB::cusparseOperation_t, m::Cint,
                                                nrhs::Cint, nnz::Cint, alpha::Ref{Cfloat},
                                                descrA::cusparseMatDescr_t,
                                                csrSortedValA::CuPtr{Cfloat},
                                                csrSortedRowPtrA::CuPtr{Cint},
                                                csrSortedColIndA::CuPtr{Cint},
                                                B::CuPtr{Cfloat}, ldb::Cint,
                                                info::csrsm2Info_t,
                                                policy::cusparseSolvePolicy_t,
                                                pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDcsrsm2_analysis(handle, algo, transA, transB, m, nrhs, nnz,
                                           alpha, descrA, csrSortedValA, csrSortedRowPtrA,
                                           csrSortedColIndA, B, ldb, info, policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDcsrsm2_analysis(handle::cusparseHandle_t, algo::Cint,
                                                transA::cusparseOperation_t,
                                                transB::cusparseOperation_t, m::Cint,
                                                nrhs::Cint, nnz::Cint, alpha::Ref{Cdouble},
                                                descrA::cusparseMatDescr_t,
                                                csrSortedValA::CuPtr{Cdouble},
                                                csrSortedRowPtrA::CuPtr{Cint},
                                                csrSortedColIndA::CuPtr{Cint},
                                                B::CuPtr{Cdouble}, ldb::Cint,
                                                info::csrsm2Info_t,
                                                policy::cusparseSolvePolicy_t,
                                                pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCcsrsm2_analysis(handle, algo, transA, transB, m, nrhs, nnz,
                                           alpha, descrA, csrSortedValA, csrSortedRowPtrA,
                                           csrSortedColIndA, B, ldb, info, policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCcsrsm2_analysis(handle::cusparseHandle_t, algo::Cint,
                                                transA::cusparseOperation_t,
                                                transB::cusparseOperation_t, m::Cint,
                                                nrhs::Cint, nnz::Cint,
                                                alpha::Ref{cuComplex},
                                                descrA::cusparseMatDescr_t,
                                                csrSortedValA::CuPtr{cuComplex},
                                                csrSortedRowPtrA::CuPtr{Cint},
                                                csrSortedColIndA::CuPtr{Cint},
                                                B::CuPtr{cuComplex}, ldb::Cint,
                                                info::csrsm2Info_t,
                                                policy::cusparseSolvePolicy_t,
                                                pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZcsrsm2_analysis(handle, algo, transA, transB, m, nrhs, nnz,
                                           alpha, descrA, csrSortedValA, csrSortedRowPtrA,
                                           csrSortedColIndA, B, ldb, info, policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZcsrsm2_analysis(handle::cusparseHandle_t, algo::Cint,
                                                transA::cusparseOperation_t,
                                                transB::cusparseOperation_t, m::Cint,
                                                nrhs::Cint, nnz::Cint,
                                                alpha::Ref{cuDoubleComplex},
                                                descrA::cusparseMatDescr_t,
                                                csrSortedValA::CuPtr{cuDoubleComplex},
                                                csrSortedRowPtrA::CuPtr{Cint},
                                                csrSortedColIndA::CuPtr{Cint},
                                                B::CuPtr{cuDoubleComplex}, ldb::Cint,
                                                info::csrsm2Info_t,
                                                policy::cusparseSolvePolicy_t,
                                                pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseScsrsm2_solve(handle, algo, transA, transB, m, nrhs, nnz, alpha,
                                        descrA, csrSortedValA, csrSortedRowPtrA,
                                        csrSortedColIndA, B, ldb, info, policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseScsrsm2_solve(handle::cusparseHandle_t, algo::Cint,
                                             transA::cusparseOperation_t,
                                             transB::cusparseOperation_t, m::Cint,
                                             nrhs::Cint, nnz::Cint, alpha::Ref{Cfloat},
                                             descrA::cusparseMatDescr_t,
                                             csrSortedValA::CuPtr{Cfloat},
                                             csrSortedRowPtrA::CuPtr{Cint},
                                             csrSortedColIndA::CuPtr{Cint},
                                             B::CuPtr{Cfloat}, ldb::Cint,
                                             info::csrsm2Info_t,
                                             policy::cusparseSolvePolicy_t,
                                             pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDcsrsm2_solve(handle, algo, transA, transB, m, nrhs, nnz, alpha,
                                        descrA, csrSortedValA, csrSortedRowPtrA,
                                        csrSortedColIndA, B, ldb, info, policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDcsrsm2_solve(handle::cusparseHandle_t, algo::Cint,
                                             transA::cusparseOperation_t,
                                             transB::cusparseOperation_t, m::Cint,
                                             nrhs::Cint, nnz::Cint, alpha::Ref{Cdouble},
                                             descrA::cusparseMatDescr_t,
                                             csrSortedValA::CuPtr{Cdouble},
                                             csrSortedRowPtrA::CuPtr{Cint},
                                             csrSortedColIndA::CuPtr{Cint},
                                             B::CuPtr{Cdouble}, ldb::Cint,
                                             info::csrsm2Info_t,
                                             policy::cusparseSolvePolicy_t,
                                             pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCcsrsm2_solve(handle, algo, transA, transB, m, nrhs, nnz, alpha,
                                        descrA, csrSortedValA, csrSortedRowPtrA,
                                        csrSortedColIndA, B, ldb, info, policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCcsrsm2_solve(handle::cusparseHandle_t, algo::Cint,
                                             transA::cusparseOperation_t,
                                             transB::cusparseOperation_t, m::Cint,
                                             nrhs::Cint, nnz::Cint, alpha::Ref{cuComplex},
                                             descrA::cusparseMatDescr_t,
                                             csrSortedValA::CuPtr{cuComplex},
                                             csrSortedRowPtrA::CuPtr{Cint},
                                             csrSortedColIndA::CuPtr{Cint},
                                             B::CuPtr{cuComplex}, ldb::Cint,
                                             info::csrsm2Info_t,
                                             policy::cusparseSolvePolicy_t,
                                             pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZcsrsm2_solve(handle, algo, transA, transB, m, nrhs, nnz, alpha,
                                        descrA, csrSortedValA, csrSortedRowPtrA,
                                        csrSortedColIndA, B, ldb, info, policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZcsrsm2_solve(handle::cusparseHandle_t, algo::Cint,
                                             transA::cusparseOperation_t,
                                             transB::cusparseOperation_t, m::Cint,
                                             nrhs::Cint, nnz::Cint,
                                             alpha::Ref{cuDoubleComplex},
                                             descrA::cusparseMatDescr_t,
                                             csrSortedValA::CuPtr{cuDoubleComplex},
                                             csrSortedRowPtrA::CuPtr{Cint},
                                             csrSortedColIndA::CuPtr{Cint},
                                             B::CuPtr{cuDoubleComplex}, ldb::Cint,
                                             info::csrsm2Info_t,
                                             policy::cusparseSolvePolicy_t,
                                             pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseXbsrsm2_zeroPivot(handle, info, position)
    initialize_context()
    @ccall libcusparse.cusparseXbsrsm2_zeroPivot(handle::cusparseHandle_t,
                                                 info::bsrsm2Info_t,
                                                 position::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseSbsrsm2_bufferSize(handle, dirA, transA, transXY, mb, n, nnzb,
                                             descrA, bsrSortedVal, bsrSortedRowPtr,
                                             bsrSortedColInd, blockSize, info,
                                             pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseSbsrsm2_bufferSize(handle::cusparseHandle_t,
                                                  dirA::cusparseDirection_t,
                                                  transA::cusparseOperation_t,
                                                  transXY::cusparseOperation_t, mb::Cint,
                                                  n::Cint, nnzb::Cint,
                                                  descrA::cusparseMatDescr_t,
                                                  bsrSortedVal::CuPtr{Cfloat},
                                                  bsrSortedRowPtr::CuPtr{Cint},
                                                  bsrSortedColInd::CuPtr{Cint},
                                                  blockSize::Cint, info::bsrsm2Info_t,
                                                  pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseDbsrsm2_bufferSize(handle, dirA, transA, transXY, mb, n, nnzb,
                                             descrA, bsrSortedVal, bsrSortedRowPtr,
                                             bsrSortedColInd, blockSize, info,
                                             pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseDbsrsm2_bufferSize(handle::cusparseHandle_t,
                                                  dirA::cusparseDirection_t,
                                                  transA::cusparseOperation_t,
                                                  transXY::cusparseOperation_t, mb::Cint,
                                                  n::Cint, nnzb::Cint,
                                                  descrA::cusparseMatDescr_t,
                                                  bsrSortedVal::CuPtr{Cdouble},
                                                  bsrSortedRowPtr::CuPtr{Cint},
                                                  bsrSortedColInd::CuPtr{Cint},
                                                  blockSize::Cint, info::bsrsm2Info_t,
                                                  pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseCbsrsm2_bufferSize(handle, dirA, transA, transXY, mb, n, nnzb,
                                             descrA, bsrSortedVal, bsrSortedRowPtr,
                                             bsrSortedColInd, blockSize, info,
                                             pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseCbsrsm2_bufferSize(handle::cusparseHandle_t,
                                                  dirA::cusparseDirection_t,
                                                  transA::cusparseOperation_t,
                                                  transXY::cusparseOperation_t, mb::Cint,
                                                  n::Cint, nnzb::Cint,
                                                  descrA::cusparseMatDescr_t,
                                                  bsrSortedVal::CuPtr{cuComplex},
                                                  bsrSortedRowPtr::CuPtr{Cint},
                                                  bsrSortedColInd::CuPtr{Cint},
                                                  blockSize::Cint, info::bsrsm2Info_t,
                                                  pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseZbsrsm2_bufferSize(handle, dirA, transA, transXY, mb, n, nnzb,
                                             descrA, bsrSortedVal, bsrSortedRowPtr,
                                             bsrSortedColInd, blockSize, info,
                                             pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseZbsrsm2_bufferSize(handle::cusparseHandle_t,
                                                  dirA::cusparseDirection_t,
                                                  transA::cusparseOperation_t,
                                                  transXY::cusparseOperation_t, mb::Cint,
                                                  n::Cint, nnzb::Cint,
                                                  descrA::cusparseMatDescr_t,
                                                  bsrSortedVal::CuPtr{cuDoubleComplex},
                                                  bsrSortedRowPtr::CuPtr{Cint},
                                                  bsrSortedColInd::CuPtr{Cint},
                                                  blockSize::Cint, info::bsrsm2Info_t,
                                                  pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseSbsrsm2_bufferSizeExt(handle, dirA, transA, transB, mb, n, nnzb,
                                                descrA, bsrSortedVal, bsrSortedRowPtr,
                                                bsrSortedColInd, blockSize, info,
                                                pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseSbsrsm2_bufferSizeExt(handle::cusparseHandle_t,
                                                     dirA::cusparseDirection_t,
                                                     transA::cusparseOperation_t,
                                                     transB::cusparseOperation_t, mb::Cint,
                                                     n::Cint, nnzb::Cint,
                                                     descrA::cusparseMatDescr_t,
                                                     bsrSortedVal::CuPtr{Cfloat},
                                                     bsrSortedRowPtr::CuPtr{Cint},
                                                     bsrSortedColInd::CuPtr{Cint},
                                                     blockSize::Cint, info::bsrsm2Info_t,
                                                     pBufferSize::CuPtr{Csize_t})::cusparseStatus_t
end

@checked function cusparseDbsrsm2_bufferSizeExt(handle, dirA, transA, transB, mb, n, nnzb,
                                                descrA, bsrSortedVal, bsrSortedRowPtr,
                                                bsrSortedColInd, blockSize, info,
                                                pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseDbsrsm2_bufferSizeExt(handle::cusparseHandle_t,
                                                     dirA::cusparseDirection_t,
                                                     transA::cusparseOperation_t,
                                                     transB::cusparseOperation_t, mb::Cint,
                                                     n::Cint, nnzb::Cint,
                                                     descrA::cusparseMatDescr_t,
                                                     bsrSortedVal::CuPtr{Cdouble},
                                                     bsrSortedRowPtr::CuPtr{Cint},
                                                     bsrSortedColInd::CuPtr{Cint},
                                                     blockSize::Cint, info::bsrsm2Info_t,
                                                     pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseCbsrsm2_bufferSizeExt(handle, dirA, transA, transB, mb, n, nnzb,
                                                descrA, bsrSortedVal, bsrSortedRowPtr,
                                                bsrSortedColInd, blockSize, info,
                                                pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseCbsrsm2_bufferSizeExt(handle::cusparseHandle_t,
                                                     dirA::cusparseDirection_t,
                                                     transA::cusparseOperation_t,
                                                     transB::cusparseOperation_t, mb::Cint,
                                                     n::Cint, nnzb::Cint,
                                                     descrA::cusparseMatDescr_t,
                                                     bsrSortedVal::CuPtr{cuComplex},
                                                     bsrSortedRowPtr::CuPtr{Cint},
                                                     bsrSortedColInd::CuPtr{Cint},
                                                     blockSize::Cint, info::bsrsm2Info_t,
                                                     pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseZbsrsm2_bufferSizeExt(handle, dirA, transA, transB, mb, n, nnzb,
                                                descrA, bsrSortedVal, bsrSortedRowPtr,
                                                bsrSortedColInd, blockSize, info,
                                                pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseZbsrsm2_bufferSizeExt(handle::cusparseHandle_t,
                                                     dirA::cusparseDirection_t,
                                                     transA::cusparseOperation_t,
                                                     transB::cusparseOperation_t, mb::Cint,
                                                     n::Cint, nnzb::Cint,
                                                     descrA::cusparseMatDescr_t,
                                                     bsrSortedVal::CuPtr{cuDoubleComplex},
                                                     bsrSortedRowPtr::CuPtr{Cint},
                                                     bsrSortedColInd::CuPtr{Cint},
                                                     blockSize::Cint, info::bsrsm2Info_t,
                                                     pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseSbsrsm2_analysis(handle, dirA, transA, transXY, mb, n, nnzb,
                                           descrA, bsrSortedVal, bsrSortedRowPtr,
                                           bsrSortedColInd, blockSize, info, policy,
                                           pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSbsrsm2_analysis(handle::cusparseHandle_t,
                                                dirA::cusparseDirection_t,
                                                transA::cusparseOperation_t,
                                                transXY::cusparseOperation_t, mb::Cint,
                                                n::Cint, nnzb::Cint,
                                                descrA::cusparseMatDescr_t,
                                                bsrSortedVal::CuPtr{Cfloat},
                                                bsrSortedRowPtr::CuPtr{Cint},
                                                bsrSortedColInd::CuPtr{Cint},
                                                blockSize::Cint, info::bsrsm2Info_t,
                                                policy::cusparseSolvePolicy_t,
                                                pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDbsrsm2_analysis(handle, dirA, transA, transXY, mb, n, nnzb,
                                           descrA, bsrSortedVal, bsrSortedRowPtr,
                                           bsrSortedColInd, blockSize, info, policy,
                                           pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDbsrsm2_analysis(handle::cusparseHandle_t,
                                                dirA::cusparseDirection_t,
                                                transA::cusparseOperation_t,
                                                transXY::cusparseOperation_t, mb::Cint,
                                                n::Cint, nnzb::Cint,
                                                descrA::cusparseMatDescr_t,
                                                bsrSortedVal::CuPtr{Cdouble},
                                                bsrSortedRowPtr::CuPtr{Cint},
                                                bsrSortedColInd::CuPtr{Cint},
                                                blockSize::Cint, info::bsrsm2Info_t,
                                                policy::cusparseSolvePolicy_t,
                                                pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCbsrsm2_analysis(handle, dirA, transA, transXY, mb, n, nnzb,
                                           descrA, bsrSortedVal, bsrSortedRowPtr,
                                           bsrSortedColInd, blockSize, info, policy,
                                           pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCbsrsm2_analysis(handle::cusparseHandle_t,
                                                dirA::cusparseDirection_t,
                                                transA::cusparseOperation_t,
                                                transXY::cusparseOperation_t, mb::Cint,
                                                n::Cint, nnzb::Cint,
                                                descrA::cusparseMatDescr_t,
                                                bsrSortedVal::CuPtr{cuComplex},
                                                bsrSortedRowPtr::CuPtr{Cint},
                                                bsrSortedColInd::CuPtr{Cint},
                                                blockSize::Cint, info::bsrsm2Info_t,
                                                policy::cusparseSolvePolicy_t,
                                                pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZbsrsm2_analysis(handle, dirA, transA, transXY, mb, n, nnzb,
                                           descrA, bsrSortedVal, bsrSortedRowPtr,
                                           bsrSortedColInd, blockSize, info, policy,
                                           pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZbsrsm2_analysis(handle::cusparseHandle_t,
                                                dirA::cusparseDirection_t,
                                                transA::cusparseOperation_t,
                                                transXY::cusparseOperation_t, mb::Cint,
                                                n::Cint, nnzb::Cint,
                                                descrA::cusparseMatDescr_t,
                                                bsrSortedVal::CuPtr{cuDoubleComplex},
                                                bsrSortedRowPtr::CuPtr{Cint},
                                                bsrSortedColInd::CuPtr{Cint},
                                                blockSize::Cint, info::bsrsm2Info_t,
                                                policy::cusparseSolvePolicy_t,
                                                pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSbsrsm2_solve(handle, dirA, transA, transXY, mb, n, nnzb, alpha,
                                        descrA, bsrSortedVal, bsrSortedRowPtr,
                                        bsrSortedColInd, blockSize, info, B, ldb, X, ldx,
                                        policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSbsrsm2_solve(handle::cusparseHandle_t,
                                             dirA::cusparseDirection_t,
                                             transA::cusparseOperation_t,
                                             transXY::cusparseOperation_t, mb::Cint,
                                             n::Cint, nnzb::Cint, alpha::Ref{Cfloat},
                                             descrA::cusparseMatDescr_t,
                                             bsrSortedVal::CuPtr{Cfloat},
                                             bsrSortedRowPtr::CuPtr{Cint},
                                             bsrSortedColInd::CuPtr{Cint}, blockSize::Cint,
                                             info::bsrsm2Info_t, B::CuPtr{Cfloat},
                                             ldb::Cint, X::CuPtr{Cfloat}, ldx::Cint,
                                             policy::cusparseSolvePolicy_t,
                                             pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDbsrsm2_solve(handle, dirA, transA, transXY, mb, n, nnzb, alpha,
                                        descrA, bsrSortedVal, bsrSortedRowPtr,
                                        bsrSortedColInd, blockSize, info, B, ldb, X, ldx,
                                        policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDbsrsm2_solve(handle::cusparseHandle_t,
                                             dirA::cusparseDirection_t,
                                             transA::cusparseOperation_t,
                                             transXY::cusparseOperation_t, mb::Cint,
                                             n::Cint, nnzb::Cint, alpha::Ref{Cdouble},
                                             descrA::cusparseMatDescr_t,
                                             bsrSortedVal::CuPtr{Cdouble},
                                             bsrSortedRowPtr::CuPtr{Cint},
                                             bsrSortedColInd::CuPtr{Cint}, blockSize::Cint,
                                             info::bsrsm2Info_t, B::CuPtr{Cdouble},
                                             ldb::Cint, X::CuPtr{Cdouble}, ldx::Cint,
                                             policy::cusparseSolvePolicy_t,
                                             pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCbsrsm2_solve(handle, dirA, transA, transXY, mb, n, nnzb, alpha,
                                        descrA, bsrSortedVal, bsrSortedRowPtr,
                                        bsrSortedColInd, blockSize, info, B, ldb, X, ldx,
                                        policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCbsrsm2_solve(handle::cusparseHandle_t,
                                             dirA::cusparseDirection_t,
                                             transA::cusparseOperation_t,
                                             transXY::cusparseOperation_t, mb::Cint,
                                             n::Cint, nnzb::Cint, alpha::Ref{cuComplex},
                                             descrA::cusparseMatDescr_t,
                                             bsrSortedVal::CuPtr{cuComplex},
                                             bsrSortedRowPtr::CuPtr{Cint},
                                             bsrSortedColInd::CuPtr{Cint}, blockSize::Cint,
                                             info::bsrsm2Info_t, B::CuPtr{cuComplex},
                                             ldb::Cint, X::CuPtr{cuComplex}, ldx::Cint,
                                             policy::cusparseSolvePolicy_t,
                                             pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZbsrsm2_solve(handle, dirA, transA, transXY, mb, n, nnzb, alpha,
                                        descrA, bsrSortedVal, bsrSortedRowPtr,
                                        bsrSortedColInd, blockSize, info, B, ldb, X, ldx,
                                        policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZbsrsm2_solve(handle::cusparseHandle_t,
                                             dirA::cusparseDirection_t,
                                             transA::cusparseOperation_t,
                                             transXY::cusparseOperation_t, mb::Cint,
                                             n::Cint, nnzb::Cint,
                                             alpha::Ref{cuDoubleComplex},
                                             descrA::cusparseMatDescr_t,
                                             bsrSortedVal::CuPtr{cuDoubleComplex},
                                             bsrSortedRowPtr::CuPtr{Cint},
                                             bsrSortedColInd::CuPtr{Cint}, blockSize::Cint,
                                             info::bsrsm2Info_t, B::CuPtr{cuDoubleComplex},
                                             ldb::Cint, X::CuPtr{cuDoubleComplex},
                                             ldx::Cint, policy::cusparseSolvePolicy_t,
                                             pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseScsrilu02_numericBoost(handle, info, enable_boost, tol, boost_val)
    initialize_context()
    @ccall libcusparse.cusparseScsrilu02_numericBoost(handle::cusparseHandle_t,
                                                      info::csrilu02Info_t,
                                                      enable_boost::Cint, tol::Ptr{Cdouble},
                                                      boost_val::Ptr{Cfloat})::cusparseStatus_t
end

@checked function cusparseDcsrilu02_numericBoost(handle, info, enable_boost, tol, boost_val)
    initialize_context()
    @ccall libcusparse.cusparseDcsrilu02_numericBoost(handle::cusparseHandle_t,
                                                      info::csrilu02Info_t,
                                                      enable_boost::Cint, tol::Ptr{Cdouble},
                                                      boost_val::Ptr{Cdouble})::cusparseStatus_t
end

@checked function cusparseCcsrilu02_numericBoost(handle, info, enable_boost, tol, boost_val)
    initialize_context()
    @ccall libcusparse.cusparseCcsrilu02_numericBoost(handle::cusparseHandle_t,
                                                      info::csrilu02Info_t,
                                                      enable_boost::Cint, tol::Ptr{Cdouble},
                                                      boost_val::Ptr{cuComplex})::cusparseStatus_t
end

@checked function cusparseZcsrilu02_numericBoost(handle, info, enable_boost, tol, boost_val)
    initialize_context()
    @ccall libcusparse.cusparseZcsrilu02_numericBoost(handle::cusparseHandle_t,
                                                      info::csrilu02Info_t,
                                                      enable_boost::Cint, tol::Ptr{Cdouble},
                                                      boost_val::Ptr{cuDoubleComplex})::cusparseStatus_t
end

@checked function cusparseXcsrilu02_zeroPivot(handle, info, position)
    initialize_context()
    @ccall libcusparse.cusparseXcsrilu02_zeroPivot(handle::cusparseHandle_t,
                                                   info::csrilu02Info_t,
                                                   position::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseScsrilu02_bufferSize(handle, m, nnz, descrA, csrSortedValA,
                                               csrSortedRowPtrA, csrSortedColIndA, info,
                                               pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseScsrilu02_bufferSize(handle::cusparseHandle_t, m::Cint,
                                                    nnz::Cint, descrA::cusparseMatDescr_t,
                                                    csrSortedValA::CuPtr{Cfloat},
                                                    csrSortedRowPtrA::CuPtr{Cint},
                                                    csrSortedColIndA::CuPtr{Cint},
                                                    info::csrilu02Info_t,
                                                    pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseDcsrilu02_bufferSize(handle, m, nnz, descrA, csrSortedValA,
                                               csrSortedRowPtrA, csrSortedColIndA, info,
                                               pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseDcsrilu02_bufferSize(handle::cusparseHandle_t, m::Cint,
                                                    nnz::Cint, descrA::cusparseMatDescr_t,
                                                    csrSortedValA::CuPtr{Cdouble},
                                                    csrSortedRowPtrA::CuPtr{Cint},
                                                    csrSortedColIndA::CuPtr{Cint},
                                                    info::csrilu02Info_t,
                                                    pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseCcsrilu02_bufferSize(handle, m, nnz, descrA, csrSortedValA,
                                               csrSortedRowPtrA, csrSortedColIndA, info,
                                               pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseCcsrilu02_bufferSize(handle::cusparseHandle_t, m::Cint,
                                                    nnz::Cint, descrA::cusparseMatDescr_t,
                                                    csrSortedValA::CuPtr{cuComplex},
                                                    csrSortedRowPtrA::CuPtr{Cint},
                                                    csrSortedColIndA::CuPtr{Cint},
                                                    info::csrilu02Info_t,
                                                    pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseZcsrilu02_bufferSize(handle, m, nnz, descrA, csrSortedValA,
                                               csrSortedRowPtrA, csrSortedColIndA, info,
                                               pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseZcsrilu02_bufferSize(handle::cusparseHandle_t, m::Cint,
                                                    nnz::Cint, descrA::cusparseMatDescr_t,
                                                    csrSortedValA::CuPtr{cuDoubleComplex},
                                                    csrSortedRowPtrA::CuPtr{Cint},
                                                    csrSortedColIndA::CuPtr{Cint},
                                                    info::csrilu02Info_t,
                                                    pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseScsrilu02_bufferSizeExt(handle, m, nnz, descrA, csrSortedVal,
                                                  csrSortedRowPtr, csrSortedColInd, info,
                                                  pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseScsrilu02_bufferSizeExt(handle::cusparseHandle_t, m::Cint,
                                                       nnz::Cint,
                                                       descrA::cusparseMatDescr_t,
                                                       csrSortedVal::CuPtr{Cfloat},
                                                       csrSortedRowPtr::CuPtr{Cint},
                                                       csrSortedColInd::CuPtr{Cint},
                                                       info::csrilu02Info_t,
                                                       pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseDcsrilu02_bufferSizeExt(handle, m, nnz, descrA, csrSortedVal,
                                                  csrSortedRowPtr, csrSortedColInd, info,
                                                  pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseDcsrilu02_bufferSizeExt(handle::cusparseHandle_t, m::Cint,
                                                       nnz::Cint,
                                                       descrA::cusparseMatDescr_t,
                                                       csrSortedVal::CuPtr{Cdouble},
                                                       csrSortedRowPtr::CuPtr{Cint},
                                                       csrSortedColInd::CuPtr{Cint},
                                                       info::csrilu02Info_t,
                                                       pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseCcsrilu02_bufferSizeExt(handle, m, nnz, descrA, csrSortedVal,
                                                  csrSortedRowPtr, csrSortedColInd, info,
                                                  pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseCcsrilu02_bufferSizeExt(handle::cusparseHandle_t, m::Cint,
                                                       nnz::Cint,
                                                       descrA::cusparseMatDescr_t,
                                                       csrSortedVal::CuPtr{cuComplex},
                                                       csrSortedRowPtr::CuPtr{Cint},
                                                       csrSortedColInd::CuPtr{Cint},
                                                       info::csrilu02Info_t,
                                                       pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseZcsrilu02_bufferSizeExt(handle, m, nnz, descrA, csrSortedVal,
                                                  csrSortedRowPtr, csrSortedColInd, info,
                                                  pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseZcsrilu02_bufferSizeExt(handle::cusparseHandle_t, m::Cint,
                                                       nnz::Cint,
                                                       descrA::cusparseMatDescr_t,
                                                       csrSortedVal::CuPtr{cuDoubleComplex},
                                                       csrSortedRowPtr::CuPtr{Cint},
                                                       csrSortedColInd::CuPtr{Cint},
                                                       info::csrilu02Info_t,
                                                       pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseScsrilu02_analysis(handle, m, nnz, descrA, csrSortedValA,
                                             csrSortedRowPtrA, csrSortedColIndA, info,
                                             policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseScsrilu02_analysis(handle::cusparseHandle_t, m::Cint,
                                                  nnz::Cint, descrA::cusparseMatDescr_t,
                                                  csrSortedValA::CuPtr{Cfloat},
                                                  csrSortedRowPtrA::CuPtr{Cint},
                                                  csrSortedColIndA::CuPtr{Cint},
                                                  info::csrilu02Info_t,
                                                  policy::cusparseSolvePolicy_t,
                                                  pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDcsrilu02_analysis(handle, m, nnz, descrA, csrSortedValA,
                                             csrSortedRowPtrA, csrSortedColIndA, info,
                                             policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDcsrilu02_analysis(handle::cusparseHandle_t, m::Cint,
                                                  nnz::Cint, descrA::cusparseMatDescr_t,
                                                  csrSortedValA::CuPtr{Cdouble},
                                                  csrSortedRowPtrA::CuPtr{Cint},
                                                  csrSortedColIndA::CuPtr{Cint},
                                                  info::csrilu02Info_t,
                                                  policy::cusparseSolvePolicy_t,
                                                  pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCcsrilu02_analysis(handle, m, nnz, descrA, csrSortedValA,
                                             csrSortedRowPtrA, csrSortedColIndA, info,
                                             policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCcsrilu02_analysis(handle::cusparseHandle_t, m::Cint,
                                                  nnz::Cint, descrA::cusparseMatDescr_t,
                                                  csrSortedValA::CuPtr{cuComplex},
                                                  csrSortedRowPtrA::CuPtr{Cint},
                                                  csrSortedColIndA::CuPtr{Cint},
                                                  info::csrilu02Info_t,
                                                  policy::cusparseSolvePolicy_t,
                                                  pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZcsrilu02_analysis(handle, m, nnz, descrA, csrSortedValA,
                                             csrSortedRowPtrA, csrSortedColIndA, info,
                                             policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZcsrilu02_analysis(handle::cusparseHandle_t, m::Cint,
                                                  nnz::Cint, descrA::cusparseMatDescr_t,
                                                  csrSortedValA::CuPtr{cuDoubleComplex},
                                                  csrSortedRowPtrA::CuPtr{Cint},
                                                  csrSortedColIndA::CuPtr{Cint},
                                                  info::csrilu02Info_t,
                                                  policy::cusparseSolvePolicy_t,
                                                  pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseScsrilu02(handle, m, nnz, descrA, csrSortedValA_valM,
                                    csrSortedRowPtrA, csrSortedColIndA, info, policy,
                                    pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseScsrilu02(handle::cusparseHandle_t, m::Cint, nnz::Cint,
                                         descrA::cusparseMatDescr_t,
                                         csrSortedValA_valM::CuPtr{Cfloat},
                                         csrSortedRowPtrA::CuPtr{Cint},
                                         csrSortedColIndA::CuPtr{Cint},
                                         info::csrilu02Info_t,
                                         policy::cusparseSolvePolicy_t,
                                         pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDcsrilu02(handle, m, nnz, descrA, csrSortedValA_valM,
                                    csrSortedRowPtrA, csrSortedColIndA, info, policy,
                                    pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDcsrilu02(handle::cusparseHandle_t, m::Cint, nnz::Cint,
                                         descrA::cusparseMatDescr_t,
                                         csrSortedValA_valM::CuPtr{Cdouble},
                                         csrSortedRowPtrA::CuPtr{Cint},
                                         csrSortedColIndA::CuPtr{Cint},
                                         info::csrilu02Info_t,
                                         policy::cusparseSolvePolicy_t,
                                         pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCcsrilu02(handle, m, nnz, descrA, csrSortedValA_valM,
                                    csrSortedRowPtrA, csrSortedColIndA, info, policy,
                                    pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCcsrilu02(handle::cusparseHandle_t, m::Cint, nnz::Cint,
                                         descrA::cusparseMatDescr_t,
                                         csrSortedValA_valM::CuPtr{cuComplex},
                                         csrSortedRowPtrA::CuPtr{Cint},
                                         csrSortedColIndA::CuPtr{Cint},
                                         info::csrilu02Info_t,
                                         policy::cusparseSolvePolicy_t,
                                         pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZcsrilu02(handle, m, nnz, descrA, csrSortedValA_valM,
                                    csrSortedRowPtrA, csrSortedColIndA, info, policy,
                                    pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZcsrilu02(handle::cusparseHandle_t, m::Cint, nnz::Cint,
                                         descrA::cusparseMatDescr_t,
                                         csrSortedValA_valM::CuPtr{cuDoubleComplex},
                                         csrSortedRowPtrA::CuPtr{Cint},
                                         csrSortedColIndA::CuPtr{Cint},
                                         info::csrilu02Info_t,
                                         policy::cusparseSolvePolicy_t,
                                         pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSbsrilu02_numericBoost(handle, info, enable_boost, tol, boost_val)
    initialize_context()
    @ccall libcusparse.cusparseSbsrilu02_numericBoost(handle::cusparseHandle_t,
                                                      info::bsrilu02Info_t,
                                                      enable_boost::Cint, tol::Ptr{Cdouble},
                                                      boost_val::Ptr{Cfloat})::cusparseStatus_t
end

@checked function cusparseDbsrilu02_numericBoost(handle, info, enable_boost, tol, boost_val)
    initialize_context()
    @ccall libcusparse.cusparseDbsrilu02_numericBoost(handle::cusparseHandle_t,
                                                      info::bsrilu02Info_t,
                                                      enable_boost::Cint, tol::Ptr{Cdouble},
                                                      boost_val::Ptr{Cdouble})::cusparseStatus_t
end

@checked function cusparseCbsrilu02_numericBoost(handle, info, enable_boost, tol, boost_val)
    initialize_context()
    @ccall libcusparse.cusparseCbsrilu02_numericBoost(handle::cusparseHandle_t,
                                                      info::bsrilu02Info_t,
                                                      enable_boost::Cint, tol::Ptr{Cdouble},
                                                      boost_val::Ptr{cuComplex})::cusparseStatus_t
end

@checked function cusparseZbsrilu02_numericBoost(handle, info, enable_boost, tol, boost_val)
    initialize_context()
    @ccall libcusparse.cusparseZbsrilu02_numericBoost(handle::cusparseHandle_t,
                                                      info::bsrilu02Info_t,
                                                      enable_boost::Cint, tol::Ptr{Cdouble},
                                                      boost_val::Ptr{cuDoubleComplex})::cusparseStatus_t
end

@checked function cusparseXbsrilu02_zeroPivot(handle, info, position)
    initialize_context()
    @ccall libcusparse.cusparseXbsrilu02_zeroPivot(handle::cusparseHandle_t,
                                                   info::bsrilu02Info_t,
                                                   position::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseSbsrilu02_bufferSize(handle, dirA, mb, nnzb, descrA, bsrSortedVal,
                                               bsrSortedRowPtr, bsrSortedColInd, blockDim,
                                               info, pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseSbsrilu02_bufferSize(handle::cusparseHandle_t,
                                                    dirA::cusparseDirection_t, mb::Cint,
                                                    nnzb::Cint, descrA::cusparseMatDescr_t,
                                                    bsrSortedVal::CuPtr{Cfloat},
                                                    bsrSortedRowPtr::CuPtr{Cint},
                                                    bsrSortedColInd::CuPtr{Cint},
                                                    blockDim::Cint, info::bsrilu02Info_t,
                                                    pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseDbsrilu02_bufferSize(handle, dirA, mb, nnzb, descrA, bsrSortedVal,
                                               bsrSortedRowPtr, bsrSortedColInd, blockDim,
                                               info, pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseDbsrilu02_bufferSize(handle::cusparseHandle_t,
                                                    dirA::cusparseDirection_t, mb::Cint,
                                                    nnzb::Cint, descrA::cusparseMatDescr_t,
                                                    bsrSortedVal::CuPtr{Cdouble},
                                                    bsrSortedRowPtr::CuPtr{Cint},
                                                    bsrSortedColInd::CuPtr{Cint},
                                                    blockDim::Cint, info::bsrilu02Info_t,
                                                    pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseCbsrilu02_bufferSize(handle, dirA, mb, nnzb, descrA, bsrSortedVal,
                                               bsrSortedRowPtr, bsrSortedColInd, blockDim,
                                               info, pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseCbsrilu02_bufferSize(handle::cusparseHandle_t,
                                                    dirA::cusparseDirection_t, mb::Cint,
                                                    nnzb::Cint, descrA::cusparseMatDescr_t,
                                                    bsrSortedVal::CuPtr{cuComplex},
                                                    bsrSortedRowPtr::CuPtr{Cint},
                                                    bsrSortedColInd::CuPtr{Cint},
                                                    blockDim::Cint, info::bsrilu02Info_t,
                                                    pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseZbsrilu02_bufferSize(handle, dirA, mb, nnzb, descrA, bsrSortedVal,
                                               bsrSortedRowPtr, bsrSortedColInd, blockDim,
                                               info, pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseZbsrilu02_bufferSize(handle::cusparseHandle_t,
                                                    dirA::cusparseDirection_t, mb::Cint,
                                                    nnzb::Cint, descrA::cusparseMatDescr_t,
                                                    bsrSortedVal::CuPtr{cuDoubleComplex},
                                                    bsrSortedRowPtr::CuPtr{Cint},
                                                    bsrSortedColInd::CuPtr{Cint},
                                                    blockDim::Cint, info::bsrilu02Info_t,
                                                    pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseSbsrilu02_bufferSizeExt(handle, dirA, mb, nnzb, descrA,
                                                  bsrSortedVal, bsrSortedRowPtr,
                                                  bsrSortedColInd, blockSize, info,
                                                  pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseSbsrilu02_bufferSizeExt(handle::cusparseHandle_t,
                                                       dirA::cusparseDirection_t, mb::Cint,
                                                       nnzb::Cint,
                                                       descrA::cusparseMatDescr_t,
                                                       bsrSortedVal::CuPtr{Cfloat},
                                                       bsrSortedRowPtr::CuPtr{Cint},
                                                       bsrSortedColInd::CuPtr{Cint},
                                                       blockSize::Cint,
                                                       info::bsrilu02Info_t,
                                                       pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseDbsrilu02_bufferSizeExt(handle, dirA, mb, nnzb, descrA,
                                                  bsrSortedVal, bsrSortedRowPtr,
                                                  bsrSortedColInd, blockSize, info,
                                                  pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseDbsrilu02_bufferSizeExt(handle::cusparseHandle_t,
                                                       dirA::cusparseDirection_t, mb::Cint,
                                                       nnzb::Cint,
                                                       descrA::cusparseMatDescr_t,
                                                       bsrSortedVal::CuPtr{Cdouble},
                                                       bsrSortedRowPtr::CuPtr{Cint},
                                                       bsrSortedColInd::CuPtr{Cint},
                                                       blockSize::Cint,
                                                       info::bsrilu02Info_t,
                                                       pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseCbsrilu02_bufferSizeExt(handle, dirA, mb, nnzb, descrA,
                                                  bsrSortedVal, bsrSortedRowPtr,
                                                  bsrSortedColInd, blockSize, info,
                                                  pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseCbsrilu02_bufferSizeExt(handle::cusparseHandle_t,
                                                       dirA::cusparseDirection_t, mb::Cint,
                                                       nnzb::Cint,
                                                       descrA::cusparseMatDescr_t,
                                                       bsrSortedVal::CuPtr{cuComplex},
                                                       bsrSortedRowPtr::CuPtr{Cint},
                                                       bsrSortedColInd::CuPtr{Cint},
                                                       blockSize::Cint,
                                                       info::bsrilu02Info_t,
                                                       pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseZbsrilu02_bufferSizeExt(handle, dirA, mb, nnzb, descrA,
                                                  bsrSortedVal, bsrSortedRowPtr,
                                                  bsrSortedColInd, blockSize, info,
                                                  pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseZbsrilu02_bufferSizeExt(handle::cusparseHandle_t,
                                                       dirA::cusparseDirection_t, mb::Cint,
                                                       nnzb::Cint,
                                                       descrA::cusparseMatDescr_t,
                                                       bsrSortedVal::CuPtr{cuDoubleComplex},
                                                       bsrSortedRowPtr::CuPtr{Cint},
                                                       bsrSortedColInd::CuPtr{Cint},
                                                       blockSize::Cint,
                                                       info::bsrilu02Info_t,
                                                       pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseSbsrilu02_analysis(handle, dirA, mb, nnzb, descrA, bsrSortedVal,
                                             bsrSortedRowPtr, bsrSortedColInd, blockDim,
                                             info, policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSbsrilu02_analysis(handle::cusparseHandle_t,
                                                  dirA::cusparseDirection_t, mb::Cint,
                                                  nnzb::Cint, descrA::cusparseMatDescr_t,
                                                  bsrSortedVal::CuPtr{Cfloat},
                                                  bsrSortedRowPtr::CuPtr{Cint},
                                                  bsrSortedColInd::CuPtr{Cint},
                                                  blockDim::Cint, info::bsrilu02Info_t,
                                                  policy::cusparseSolvePolicy_t,
                                                  pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDbsrilu02_analysis(handle, dirA, mb, nnzb, descrA, bsrSortedVal,
                                             bsrSortedRowPtr, bsrSortedColInd, blockDim,
                                             info, policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDbsrilu02_analysis(handle::cusparseHandle_t,
                                                  dirA::cusparseDirection_t, mb::Cint,
                                                  nnzb::Cint, descrA::cusparseMatDescr_t,
                                                  bsrSortedVal::CuPtr{Cdouble},
                                                  bsrSortedRowPtr::CuPtr{Cint},
                                                  bsrSortedColInd::CuPtr{Cint},
                                                  blockDim::Cint, info::bsrilu02Info_t,
                                                  policy::cusparseSolvePolicy_t,
                                                  pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCbsrilu02_analysis(handle, dirA, mb, nnzb, descrA, bsrSortedVal,
                                             bsrSortedRowPtr, bsrSortedColInd, blockDim,
                                             info, policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCbsrilu02_analysis(handle::cusparseHandle_t,
                                                  dirA::cusparseDirection_t, mb::Cint,
                                                  nnzb::Cint, descrA::cusparseMatDescr_t,
                                                  bsrSortedVal::CuPtr{cuComplex},
                                                  bsrSortedRowPtr::CuPtr{Cint},
                                                  bsrSortedColInd::CuPtr{Cint},
                                                  blockDim::Cint, info::bsrilu02Info_t,
                                                  policy::cusparseSolvePolicy_t,
                                                  pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZbsrilu02_analysis(handle, dirA, mb, nnzb, descrA, bsrSortedVal,
                                             bsrSortedRowPtr, bsrSortedColInd, blockDim,
                                             info, policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZbsrilu02_analysis(handle::cusparseHandle_t,
                                                  dirA::cusparseDirection_t, mb::Cint,
                                                  nnzb::Cint, descrA::cusparseMatDescr_t,
                                                  bsrSortedVal::CuPtr{cuDoubleComplex},
                                                  bsrSortedRowPtr::CuPtr{Cint},
                                                  bsrSortedColInd::CuPtr{Cint},
                                                  blockDim::Cint, info::bsrilu02Info_t,
                                                  policy::cusparseSolvePolicy_t,
                                                  pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSbsrilu02(handle, dirA, mb, nnzb, descrA, bsrSortedVal,
                                    bsrSortedRowPtr, bsrSortedColInd, blockDim, info,
                                    policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSbsrilu02(handle::cusparseHandle_t,
                                         dirA::cusparseDirection_t, mb::Cint, nnzb::Cint,
                                         descrA::cusparseMatDescr_t,
                                         bsrSortedVal::CuPtr{Cfloat},
                                         bsrSortedRowPtr::CuPtr{Cint},
                                         bsrSortedColInd::CuPtr{Cint}, blockDim::Cint,
                                         info::bsrilu02Info_t,
                                         policy::cusparseSolvePolicy_t,
                                         pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDbsrilu02(handle, dirA, mb, nnzb, descrA, bsrSortedVal,
                                    bsrSortedRowPtr, bsrSortedColInd, blockDim, info,
                                    policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDbsrilu02(handle::cusparseHandle_t,
                                         dirA::cusparseDirection_t, mb::Cint, nnzb::Cint,
                                         descrA::cusparseMatDescr_t,
                                         bsrSortedVal::CuPtr{Cdouble},
                                         bsrSortedRowPtr::CuPtr{Cint},
                                         bsrSortedColInd::CuPtr{Cint}, blockDim::Cint,
                                         info::bsrilu02Info_t,
                                         policy::cusparseSolvePolicy_t,
                                         pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCbsrilu02(handle, dirA, mb, nnzb, descrA, bsrSortedVal,
                                    bsrSortedRowPtr, bsrSortedColInd, blockDim, info,
                                    policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCbsrilu02(handle::cusparseHandle_t,
                                         dirA::cusparseDirection_t, mb::Cint, nnzb::Cint,
                                         descrA::cusparseMatDescr_t,
                                         bsrSortedVal::CuPtr{cuComplex},
                                         bsrSortedRowPtr::CuPtr{Cint},
                                         bsrSortedColInd::CuPtr{Cint}, blockDim::Cint,
                                         info::bsrilu02Info_t,
                                         policy::cusparseSolvePolicy_t,
                                         pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZbsrilu02(handle, dirA, mb, nnzb, descrA, bsrSortedVal,
                                    bsrSortedRowPtr, bsrSortedColInd, blockDim, info,
                                    policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZbsrilu02(handle::cusparseHandle_t,
                                         dirA::cusparseDirection_t, mb::Cint, nnzb::Cint,
                                         descrA::cusparseMatDescr_t,
                                         bsrSortedVal::CuPtr{cuDoubleComplex},
                                         bsrSortedRowPtr::CuPtr{Cint},
                                         bsrSortedColInd::CuPtr{Cint}, blockDim::Cint,
                                         info::bsrilu02Info_t,
                                         policy::cusparseSolvePolicy_t,
                                         pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseXcsric02_zeroPivot(handle, info, position)
    initialize_context()
    @ccall libcusparse.cusparseXcsric02_zeroPivot(handle::cusparseHandle_t,
                                                  info::csric02Info_t,
                                                  position::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseScsric02_bufferSize(handle, m, nnz, descrA, csrSortedValA,
                                              csrSortedRowPtrA, csrSortedColIndA, info,
                                              pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseScsric02_bufferSize(handle::cusparseHandle_t, m::Cint,
                                                   nnz::Cint, descrA::cusparseMatDescr_t,
                                                   csrSortedValA::CuPtr{Cfloat},
                                                   csrSortedRowPtrA::CuPtr{Cint},
                                                   csrSortedColIndA::CuPtr{Cint},
                                                   info::csric02Info_t,
                                                   pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseDcsric02_bufferSize(handle, m, nnz, descrA, csrSortedValA,
                                              csrSortedRowPtrA, csrSortedColIndA, info,
                                              pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseDcsric02_bufferSize(handle::cusparseHandle_t, m::Cint,
                                                   nnz::Cint, descrA::cusparseMatDescr_t,
                                                   csrSortedValA::CuPtr{Cdouble},
                                                   csrSortedRowPtrA::CuPtr{Cint},
                                                   csrSortedColIndA::CuPtr{Cint},
                                                   info::csric02Info_t,
                                                   pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseCcsric02_bufferSize(handle, m, nnz, descrA, csrSortedValA,
                                              csrSortedRowPtrA, csrSortedColIndA, info,
                                              pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseCcsric02_bufferSize(handle::cusparseHandle_t, m::Cint,
                                                   nnz::Cint, descrA::cusparseMatDescr_t,
                                                   csrSortedValA::CuPtr{cuComplex},
                                                   csrSortedRowPtrA::CuPtr{Cint},
                                                   csrSortedColIndA::CuPtr{Cint},
                                                   info::csric02Info_t,
                                                   pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseZcsric02_bufferSize(handle, m, nnz, descrA, csrSortedValA,
                                              csrSortedRowPtrA, csrSortedColIndA, info,
                                              pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseZcsric02_bufferSize(handle::cusparseHandle_t, m::Cint,
                                                   nnz::Cint, descrA::cusparseMatDescr_t,
                                                   csrSortedValA::CuPtr{cuDoubleComplex},
                                                   csrSortedRowPtrA::CuPtr{Cint},
                                                   csrSortedColIndA::CuPtr{Cint},
                                                   info::csric02Info_t,
                                                   pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseScsric02_bufferSizeExt(handle, m, nnz, descrA, csrSortedVal,
                                                 csrSortedRowPtr, csrSortedColInd, info,
                                                 pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseScsric02_bufferSizeExt(handle::cusparseHandle_t, m::Cint,
                                                      nnz::Cint, descrA::cusparseMatDescr_t,
                                                      csrSortedVal::CuPtr{Cfloat},
                                                      csrSortedRowPtr::CuPtr{Cint},
                                                      csrSortedColInd::CuPtr{Cint},
                                                      info::csric02Info_t,
                                                      pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseDcsric02_bufferSizeExt(handle, m, nnz, descrA, csrSortedVal,
                                                 csrSortedRowPtr, csrSortedColInd, info,
                                                 pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseDcsric02_bufferSizeExt(handle::cusparseHandle_t, m::Cint,
                                                      nnz::Cint, descrA::cusparseMatDescr_t,
                                                      csrSortedVal::CuPtr{Cdouble},
                                                      csrSortedRowPtr::CuPtr{Cint},
                                                      csrSortedColInd::CuPtr{Cint},
                                                      info::csric02Info_t,
                                                      pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseCcsric02_bufferSizeExt(handle, m, nnz, descrA, csrSortedVal,
                                                 csrSortedRowPtr, csrSortedColInd, info,
                                                 pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseCcsric02_bufferSizeExt(handle::cusparseHandle_t, m::Cint,
                                                      nnz::Cint, descrA::cusparseMatDescr_t,
                                                      csrSortedVal::CuPtr{cuComplex},
                                                      csrSortedRowPtr::CuPtr{Cint},
                                                      csrSortedColInd::CuPtr{Cint},
                                                      info::csric02Info_t,
                                                      pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseZcsric02_bufferSizeExt(handle, m, nnz, descrA, csrSortedVal,
                                                 csrSortedRowPtr, csrSortedColInd, info,
                                                 pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseZcsric02_bufferSizeExt(handle::cusparseHandle_t, m::Cint,
                                                      nnz::Cint, descrA::cusparseMatDescr_t,
                                                      csrSortedVal::CuPtr{cuDoubleComplex},
                                                      csrSortedRowPtr::CuPtr{Cint},
                                                      csrSortedColInd::CuPtr{Cint},
                                                      info::csric02Info_t,
                                                      pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseScsric02_analysis(handle, m, nnz, descrA, csrSortedValA,
                                            csrSortedRowPtrA, csrSortedColIndA, info,
                                            policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseScsric02_analysis(handle::cusparseHandle_t, m::Cint,
                                                 nnz::Cint, descrA::cusparseMatDescr_t,
                                                 csrSortedValA::CuPtr{Cfloat},
                                                 csrSortedRowPtrA::CuPtr{Cint},
                                                 csrSortedColIndA::CuPtr{Cint},
                                                 info::csric02Info_t,
                                                 policy::cusparseSolvePolicy_t,
                                                 pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDcsric02_analysis(handle, m, nnz, descrA, csrSortedValA,
                                            csrSortedRowPtrA, csrSortedColIndA, info,
                                            policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDcsric02_analysis(handle::cusparseHandle_t, m::Cint,
                                                 nnz::Cint, descrA::cusparseMatDescr_t,
                                                 csrSortedValA::CuPtr{Cdouble},
                                                 csrSortedRowPtrA::CuPtr{Cint},
                                                 csrSortedColIndA::CuPtr{Cint},
                                                 info::csric02Info_t,
                                                 policy::cusparseSolvePolicy_t,
                                                 pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCcsric02_analysis(handle, m, nnz, descrA, csrSortedValA,
                                            csrSortedRowPtrA, csrSortedColIndA, info,
                                            policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCcsric02_analysis(handle::cusparseHandle_t, m::Cint,
                                                 nnz::Cint, descrA::cusparseMatDescr_t,
                                                 csrSortedValA::CuPtr{cuComplex},
                                                 csrSortedRowPtrA::CuPtr{Cint},
                                                 csrSortedColIndA::CuPtr{Cint},
                                                 info::csric02Info_t,
                                                 policy::cusparseSolvePolicy_t,
                                                 pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZcsric02_analysis(handle, m, nnz, descrA, csrSortedValA,
                                            csrSortedRowPtrA, csrSortedColIndA, info,
                                            policy, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZcsric02_analysis(handle::cusparseHandle_t, m::Cint,
                                                 nnz::Cint, descrA::cusparseMatDescr_t,
                                                 csrSortedValA::CuPtr{cuDoubleComplex},
                                                 csrSortedRowPtrA::CuPtr{Cint},
                                                 csrSortedColIndA::CuPtr{Cint},
                                                 info::csric02Info_t,
                                                 policy::cusparseSolvePolicy_t,
                                                 pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseScsric02(handle, m, nnz, descrA, csrSortedValA_valM,
                                   csrSortedRowPtrA, csrSortedColIndA, info, policy,
                                   pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseScsric02(handle::cusparseHandle_t, m::Cint, nnz::Cint,
                                        descrA::cusparseMatDescr_t,
                                        csrSortedValA_valM::CuPtr{Cfloat},
                                        csrSortedRowPtrA::CuPtr{Cint},
                                        csrSortedColIndA::CuPtr{Cint}, info::csric02Info_t,
                                        policy::cusparseSolvePolicy_t,
                                        pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDcsric02(handle, m, nnz, descrA, csrSortedValA_valM,
                                   csrSortedRowPtrA, csrSortedColIndA, info, policy,
                                   pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDcsric02(handle::cusparseHandle_t, m::Cint, nnz::Cint,
                                        descrA::cusparseMatDescr_t,
                                        csrSortedValA_valM::CuPtr{Cdouble},
                                        csrSortedRowPtrA::CuPtr{Cint},
                                        csrSortedColIndA::CuPtr{Cint}, info::csric02Info_t,
                                        policy::cusparseSolvePolicy_t,
                                        pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCcsric02(handle, m, nnz, descrA, csrSortedValA_valM,
                                   csrSortedRowPtrA, csrSortedColIndA, info, policy,
                                   pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCcsric02(handle::cusparseHandle_t, m::Cint, nnz::Cint,
                                        descrA::cusparseMatDescr_t,
                                        csrSortedValA_valM::CuPtr{cuComplex},
                                        csrSortedRowPtrA::CuPtr{Cint},
                                        csrSortedColIndA::CuPtr{Cint}, info::csric02Info_t,
                                        policy::cusparseSolvePolicy_t,
                                        pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZcsric02(handle, m, nnz, descrA, csrSortedValA_valM,
                                   csrSortedRowPtrA, csrSortedColIndA, info, policy,
                                   pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZcsric02(handle::cusparseHandle_t, m::Cint, nnz::Cint,
                                        descrA::cusparseMatDescr_t,
                                        csrSortedValA_valM::CuPtr{cuDoubleComplex},
                                        csrSortedRowPtrA::CuPtr{Cint},
                                        csrSortedColIndA::CuPtr{Cint}, info::csric02Info_t,
                                        policy::cusparseSolvePolicy_t,
                                        pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseXbsric02_zeroPivot(handle, info, position)
    initialize_context()
    @ccall libcusparse.cusparseXbsric02_zeroPivot(handle::cusparseHandle_t,
                                                  info::bsric02Info_t,
                                                  position::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseSbsric02_bufferSize(handle, dirA, mb, nnzb, descrA, bsrSortedVal,
                                              bsrSortedRowPtr, bsrSortedColInd, blockDim,
                                              info, pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseSbsric02_bufferSize(handle::cusparseHandle_t,
                                                   dirA::cusparseDirection_t, mb::Cint,
                                                   nnzb::Cint, descrA::cusparseMatDescr_t,
                                                   bsrSortedVal::CuPtr{Cfloat},
                                                   bsrSortedRowPtr::CuPtr{Cint},
                                                   bsrSortedColInd::CuPtr{Cint},
                                                   blockDim::Cint, info::bsric02Info_t,
                                                   pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseDbsric02_bufferSize(handle, dirA, mb, nnzb, descrA, bsrSortedVal,
                                              bsrSortedRowPtr, bsrSortedColInd, blockDim,
                                              info, pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseDbsric02_bufferSize(handle::cusparseHandle_t,
                                                   dirA::cusparseDirection_t, mb::Cint,
                                                   nnzb::Cint, descrA::cusparseMatDescr_t,
                                                   bsrSortedVal::CuPtr{Cdouble},
                                                   bsrSortedRowPtr::CuPtr{Cint},
                                                   bsrSortedColInd::CuPtr{Cint},
                                                   blockDim::Cint, info::bsric02Info_t,
                                                   pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseCbsric02_bufferSize(handle, dirA, mb, nnzb, descrA, bsrSortedVal,
                                              bsrSortedRowPtr, bsrSortedColInd, blockDim,
                                              info, pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseCbsric02_bufferSize(handle::cusparseHandle_t,
                                                   dirA::cusparseDirection_t, mb::Cint,
                                                   nnzb::Cint, descrA::cusparseMatDescr_t,
                                                   bsrSortedVal::CuPtr{cuComplex},
                                                   bsrSortedRowPtr::CuPtr{Cint},
                                                   bsrSortedColInd::CuPtr{Cint},
                                                   blockDim::Cint, info::bsric02Info_t,
                                                   pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseZbsric02_bufferSize(handle, dirA, mb, nnzb, descrA, bsrSortedVal,
                                              bsrSortedRowPtr, bsrSortedColInd, blockDim,
                                              info, pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseZbsric02_bufferSize(handle::cusparseHandle_t,
                                                   dirA::cusparseDirection_t, mb::Cint,
                                                   nnzb::Cint, descrA::cusparseMatDescr_t,
                                                   bsrSortedVal::CuPtr{cuDoubleComplex},
                                                   bsrSortedRowPtr::CuPtr{Cint},
                                                   bsrSortedColInd::CuPtr{Cint},
                                                   blockDim::Cint, info::bsric02Info_t,
                                                   pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseSbsric02_bufferSizeExt(handle, dirA, mb, nnzb, descrA,
                                                 bsrSortedVal, bsrSortedRowPtr,
                                                 bsrSortedColInd, blockSize, info,
                                                 pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseSbsric02_bufferSizeExt(handle::cusparseHandle_t,
                                                      dirA::cusparseDirection_t, mb::Cint,
                                                      nnzb::Cint,
                                                      descrA::cusparseMatDescr_t,
                                                      bsrSortedVal::CuPtr{Cfloat},
                                                      bsrSortedRowPtr::CuPtr{Cint},
                                                      bsrSortedColInd::CuPtr{Cint},
                                                      blockSize::Cint, info::bsric02Info_t,
                                                      pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseDbsric02_bufferSizeExt(handle, dirA, mb, nnzb, descrA,
                                                 bsrSortedVal, bsrSortedRowPtr,
                                                 bsrSortedColInd, blockSize, info,
                                                 pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseDbsric02_bufferSizeExt(handle::cusparseHandle_t,
                                                      dirA::cusparseDirection_t, mb::Cint,
                                                      nnzb::Cint,
                                                      descrA::cusparseMatDescr_t,
                                                      bsrSortedVal::CuPtr{Cdouble},
                                                      bsrSortedRowPtr::CuPtr{Cint},
                                                      bsrSortedColInd::CuPtr{Cint},
                                                      blockSize::Cint, info::bsric02Info_t,
                                                      pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseCbsric02_bufferSizeExt(handle, dirA, mb, nnzb, descrA,
                                                 bsrSortedVal, bsrSortedRowPtr,
                                                 bsrSortedColInd, blockSize, info,
                                                 pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseCbsric02_bufferSizeExt(handle::cusparseHandle_t,
                                                      dirA::cusparseDirection_t, mb::Cint,
                                                      nnzb::Cint,
                                                      descrA::cusparseMatDescr_t,
                                                      bsrSortedVal::CuPtr{cuComplex},
                                                      bsrSortedRowPtr::CuPtr{Cint},
                                                      bsrSortedColInd::CuPtr{Cint},
                                                      blockSize::Cint, info::bsric02Info_t,
                                                      pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseZbsric02_bufferSizeExt(handle, dirA, mb, nnzb, descrA,
                                                 bsrSortedVal, bsrSortedRowPtr,
                                                 bsrSortedColInd, blockSize, info,
                                                 pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseZbsric02_bufferSizeExt(handle::cusparseHandle_t,
                                                      dirA::cusparseDirection_t, mb::Cint,
                                                      nnzb::Cint,
                                                      descrA::cusparseMatDescr_t,
                                                      bsrSortedVal::CuPtr{cuDoubleComplex},
                                                      bsrSortedRowPtr::CuPtr{Cint},
                                                      bsrSortedColInd::CuPtr{Cint},
                                                      blockSize::Cint, info::bsric02Info_t,
                                                      pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseSbsric02_analysis(handle, dirA, mb, nnzb, descrA, bsrSortedVal,
                                            bsrSortedRowPtr, bsrSortedColInd, blockDim,
                                            info, policy, pInputBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSbsric02_analysis(handle::cusparseHandle_t,
                                                 dirA::cusparseDirection_t, mb::Cint,
                                                 nnzb::Cint, descrA::cusparseMatDescr_t,
                                                 bsrSortedVal::CuPtr{Cfloat},
                                                 bsrSortedRowPtr::CuPtr{Cint},
                                                 bsrSortedColInd::CuPtr{Cint},
                                                 blockDim::Cint, info::bsric02Info_t,
                                                 policy::cusparseSolvePolicy_t,
                                                 pInputBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDbsric02_analysis(handle, dirA, mb, nnzb, descrA, bsrSortedVal,
                                            bsrSortedRowPtr, bsrSortedColInd, blockDim,
                                            info, policy, pInputBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDbsric02_analysis(handle::cusparseHandle_t,
                                                 dirA::cusparseDirection_t, mb::Cint,
                                                 nnzb::Cint, descrA::cusparseMatDescr_t,
                                                 bsrSortedVal::CuPtr{Cdouble},
                                                 bsrSortedRowPtr::CuPtr{Cint},
                                                 bsrSortedColInd::CuPtr{Cint},
                                                 blockDim::Cint, info::bsric02Info_t,
                                                 policy::cusparseSolvePolicy_t,
                                                 pInputBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCbsric02_analysis(handle, dirA, mb, nnzb, descrA, bsrSortedVal,
                                            bsrSortedRowPtr, bsrSortedColInd, blockDim,
                                            info, policy, pInputBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCbsric02_analysis(handle::cusparseHandle_t,
                                                 dirA::cusparseDirection_t, mb::Cint,
                                                 nnzb::Cint, descrA::cusparseMatDescr_t,
                                                 bsrSortedVal::CuPtr{cuComplex},
                                                 bsrSortedRowPtr::CuPtr{Cint},
                                                 bsrSortedColInd::CuPtr{Cint},
                                                 blockDim::Cint, info::bsric02Info_t,
                                                 policy::cusparseSolvePolicy_t,
                                                 pInputBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZbsric02_analysis(handle, dirA, mb, nnzb, descrA, bsrSortedVal,
                                            bsrSortedRowPtr, bsrSortedColInd, blockDim,
                                            info, policy, pInputBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZbsric02_analysis(handle::cusparseHandle_t,
                                                 dirA::cusparseDirection_t, mb::Cint,
                                                 nnzb::Cint, descrA::cusparseMatDescr_t,
                                                 bsrSortedVal::CuPtr{cuDoubleComplex},
                                                 bsrSortedRowPtr::CuPtr{Cint},
                                                 bsrSortedColInd::CuPtr{Cint},
                                                 blockDim::Cint, info::bsric02Info_t,
                                                 policy::cusparseSolvePolicy_t,
                                                 pInputBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSbsric02(handle, dirA, mb, nnzb, descrA, bsrSortedVal,
                                   bsrSortedRowPtr, bsrSortedColInd, blockDim, info, policy,
                                   pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSbsric02(handle::cusparseHandle_t, dirA::cusparseDirection_t,
                                        mb::Cint, nnzb::Cint, descrA::cusparseMatDescr_t,
                                        bsrSortedVal::CuPtr{Cfloat},
                                        bsrSortedRowPtr::CuPtr{Cint},
                                        bsrSortedColInd::CuPtr{Cint}, blockDim::Cint,
                                        info::bsric02Info_t, policy::cusparseSolvePolicy_t,
                                        pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDbsric02(handle, dirA, mb, nnzb, descrA, bsrSortedVal,
                                   bsrSortedRowPtr, bsrSortedColInd, blockDim, info, policy,
                                   pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDbsric02(handle::cusparseHandle_t, dirA::cusparseDirection_t,
                                        mb::Cint, nnzb::Cint, descrA::cusparseMatDescr_t,
                                        bsrSortedVal::CuPtr{Cdouble},
                                        bsrSortedRowPtr::CuPtr{Cint},
                                        bsrSortedColInd::CuPtr{Cint}, blockDim::Cint,
                                        info::bsric02Info_t, policy::cusparseSolvePolicy_t,
                                        pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCbsric02(handle, dirA, mb, nnzb, descrA, bsrSortedVal,
                                   bsrSortedRowPtr, bsrSortedColInd, blockDim, info, policy,
                                   pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCbsric02(handle::cusparseHandle_t, dirA::cusparseDirection_t,
                                        mb::Cint, nnzb::Cint, descrA::cusparseMatDescr_t,
                                        bsrSortedVal::CuPtr{cuComplex},
                                        bsrSortedRowPtr::CuPtr{Cint},
                                        bsrSortedColInd::CuPtr{Cint}, blockDim::Cint,
                                        info::bsric02Info_t, policy::cusparseSolvePolicy_t,
                                        pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZbsric02(handle, dirA, mb, nnzb, descrA, bsrSortedVal,
                                   bsrSortedRowPtr, bsrSortedColInd, blockDim, info, policy,
                                   pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZbsric02(handle::cusparseHandle_t, dirA::cusparseDirection_t,
                                        mb::Cint, nnzb::Cint, descrA::cusparseMatDescr_t,
                                        bsrSortedVal::CuPtr{cuDoubleComplex},
                                        bsrSortedRowPtr::CuPtr{Cint},
                                        bsrSortedColInd::CuPtr{Cint}, blockDim::Cint,
                                        info::bsric02Info_t, policy::cusparseSolvePolicy_t,
                                        pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSgtsv2_bufferSizeExt(handle, m, n, dl, d, du, B, ldb,
                                               bufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseSgtsv2_bufferSizeExt(handle::cusparseHandle_t, m::Cint,
                                                    n::Cint, dl::CuPtr{Cfloat},
                                                    d::CuPtr{Cfloat}, du::CuPtr{Cfloat},
                                                    B::CuPtr{Cfloat}, ldb::Cint,
                                                    bufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseDgtsv2_bufferSizeExt(handle, m, n, dl, d, du, B, ldb,
                                               bufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseDgtsv2_bufferSizeExt(handle::cusparseHandle_t, m::Cint,
                                                    n::Cint, dl::CuPtr{Cdouble},
                                                    d::CuPtr{Cdouble}, du::CuPtr{Cdouble},
                                                    B::CuPtr{Cdouble}, ldb::Cint,
                                                    bufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseCgtsv2_bufferSizeExt(handle, m, n, dl, d, du, B, ldb,
                                               bufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseCgtsv2_bufferSizeExt(handle::cusparseHandle_t, m::Cint,
                                                    n::Cint, dl::CuPtr{cuComplex},
                                                    d::CuPtr{cuComplex},
                                                    du::CuPtr{cuComplex},
                                                    B::CuPtr{cuComplex}, ldb::Cint,
                                                    bufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseZgtsv2_bufferSizeExt(handle, m, n, dl, d, du, B, ldb,
                                               bufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseZgtsv2_bufferSizeExt(handle::cusparseHandle_t, m::Cint,
                                                    n::Cint, dl::CuPtr{cuDoubleComplex},
                                                    d::CuPtr{cuDoubleComplex},
                                                    du::CuPtr{cuDoubleComplex},
                                                    B::CuPtr{cuDoubleComplex}, ldb::Cint,
                                                    bufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseSgtsv2(handle, m, n, dl, d, du, B, ldb, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSgtsv2(handle::cusparseHandle_t, m::Cint, n::Cint,
                                      dl::CuPtr{Cfloat}, d::CuPtr{Cfloat},
                                      du::CuPtr{Cfloat}, B::CuPtr{Cfloat}, ldb::Cint,
                                      pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDgtsv2(handle, m, n, dl, d, du, B, ldb, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDgtsv2(handle::cusparseHandle_t, m::Cint, n::Cint,
                                      dl::CuPtr{Cdouble}, d::CuPtr{Cdouble},
                                      du::CuPtr{Cdouble}, B::CuPtr{Cdouble}, ldb::Cint,
                                      pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCgtsv2(handle, m, n, dl, d, du, B, ldb, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCgtsv2(handle::cusparseHandle_t, m::Cint, n::Cint,
                                      dl::CuPtr{cuComplex}, d::CuPtr{cuComplex},
                                      du::CuPtr{cuComplex}, B::CuPtr{cuComplex}, ldb::Cint,
                                      pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZgtsv2(handle, m, n, dl, d, du, B, ldb, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZgtsv2(handle::cusparseHandle_t, m::Cint, n::Cint,
                                      dl::CuPtr{cuDoubleComplex}, d::CuPtr{cuDoubleComplex},
                                      du::CuPtr{cuDoubleComplex}, B::CuPtr{cuDoubleComplex},
                                      ldb::Cint, pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSgtsv2_nopivot_bufferSizeExt(handle, m, n, dl, d, du, B, ldb,
                                                       bufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseSgtsv2_nopivot_bufferSizeExt(handle::cusparseHandle_t,
                                                            m::Cint, n::Cint,
                                                            dl::CuPtr{Cfloat},
                                                            d::CuPtr{Cfloat},
                                                            du::CuPtr{Cfloat},
                                                            B::CuPtr{Cfloat}, ldb::Cint,
                                                            bufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseDgtsv2_nopivot_bufferSizeExt(handle, m, n, dl, d, du, B, ldb,
                                                       bufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseDgtsv2_nopivot_bufferSizeExt(handle::cusparseHandle_t,
                                                            m::Cint, n::Cint,
                                                            dl::CuPtr{Cdouble},
                                                            d::CuPtr{Cdouble},
                                                            du::CuPtr{Cdouble},
                                                            B::CuPtr{Cdouble}, ldb::Cint,
                                                            bufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseCgtsv2_nopivot_bufferSizeExt(handle, m, n, dl, d, du, B, ldb,
                                                       bufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseCgtsv2_nopivot_bufferSizeExt(handle::cusparseHandle_t,
                                                            m::Cint, n::Cint,
                                                            dl::CuPtr{cuComplex},
                                                            d::CuPtr{cuComplex},
                                                            du::CuPtr{cuComplex},
                                                            B::CuPtr{cuComplex}, ldb::Cint,
                                                            bufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseZgtsv2_nopivot_bufferSizeExt(handle, m, n, dl, d, du, B, ldb,
                                                       bufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseZgtsv2_nopivot_bufferSizeExt(handle::cusparseHandle_t,
                                                            m::Cint, n::Cint,
                                                            dl::CuPtr{cuDoubleComplex},
                                                            d::CuPtr{cuDoubleComplex},
                                                            du::CuPtr{cuDoubleComplex},
                                                            B::CuPtr{cuDoubleComplex},
                                                            ldb::Cint,
                                                            bufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseSgtsv2_nopivot(handle, m, n, dl, d, du, B, ldb, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSgtsv2_nopivot(handle::cusparseHandle_t, m::Cint, n::Cint,
                                              dl::CuPtr{Cfloat}, d::CuPtr{Cfloat},
                                              du::CuPtr{Cfloat}, B::CuPtr{Cfloat},
                                              ldb::Cint,
                                              pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDgtsv2_nopivot(handle, m, n, dl, d, du, B, ldb, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDgtsv2_nopivot(handle::cusparseHandle_t, m::Cint, n::Cint,
                                              dl::CuPtr{Cdouble}, d::CuPtr{Cdouble},
                                              du::CuPtr{Cdouble}, B::CuPtr{Cdouble},
                                              ldb::Cint,
                                              pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCgtsv2_nopivot(handle, m, n, dl, d, du, B, ldb, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCgtsv2_nopivot(handle::cusparseHandle_t, m::Cint, n::Cint,
                                              dl::CuPtr{cuComplex}, d::CuPtr{cuComplex},
                                              du::CuPtr{cuComplex}, B::CuPtr{cuComplex},
                                              ldb::Cint,
                                              pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZgtsv2_nopivot(handle, m, n, dl, d, du, B, ldb, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZgtsv2_nopivot(handle::cusparseHandle_t, m::Cint, n::Cint,
                                              dl::CuPtr{cuDoubleComplex},
                                              d::CuPtr{cuDoubleComplex},
                                              du::CuPtr{cuDoubleComplex},
                                              B::CuPtr{cuDoubleComplex}, ldb::Cint,
                                              pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSgtsv2StridedBatch_bufferSizeExt(handle, m, dl, d, du, x,
                                                           batchCount, batchStride,
                                                           bufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseSgtsv2StridedBatch_bufferSizeExt(handle::cusparseHandle_t,
                                                                m::Cint, dl::CuPtr{Cfloat},
                                                                d::CuPtr{Cfloat},
                                                                du::CuPtr{Cfloat},
                                                                x::CuPtr{Cfloat},
                                                                batchCount::Cint,
                                                                batchStride::Cint,
                                                                bufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseDgtsv2StridedBatch_bufferSizeExt(handle, m, dl, d, du, x,
                                                           batchCount, batchStride,
                                                           bufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseDgtsv2StridedBatch_bufferSizeExt(handle::cusparseHandle_t,
                                                                m::Cint, dl::CuPtr{Cdouble},
                                                                d::CuPtr{Cdouble},
                                                                du::CuPtr{Cdouble},
                                                                x::CuPtr{Cdouble},
                                                                batchCount::Cint,
                                                                batchStride::Cint,
                                                                bufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseCgtsv2StridedBatch_bufferSizeExt(handle, m, dl, d, du, x,
                                                           batchCount, batchStride,
                                                           bufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseCgtsv2StridedBatch_bufferSizeExt(handle::cusparseHandle_t,
                                                                m::Cint,
                                                                dl::CuPtr{cuComplex},
                                                                d::CuPtr{cuComplex},
                                                                du::CuPtr{cuComplex},
                                                                x::CuPtr{cuComplex},
                                                                batchCount::Cint,
                                                                batchStride::Cint,
                                                                bufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseZgtsv2StridedBatch_bufferSizeExt(handle, m, dl, d, du, x,
                                                           batchCount, batchStride,
                                                           bufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseZgtsv2StridedBatch_bufferSizeExt(handle::cusparseHandle_t,
                                                                m::Cint,
                                                                dl::CuPtr{cuDoubleComplex},
                                                                d::CuPtr{cuDoubleComplex},
                                                                du::CuPtr{cuDoubleComplex},
                                                                x::CuPtr{cuDoubleComplex},
                                                                batchCount::Cint,
                                                                batchStride::Cint,
                                                                bufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseSgtsv2StridedBatch(handle, m, dl, d, du, x, batchCount,
                                             batchStride, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSgtsv2StridedBatch(handle::cusparseHandle_t, m::Cint,
                                                  dl::CuPtr{Cfloat}, d::CuPtr{Cfloat},
                                                  du::CuPtr{Cfloat}, x::CuPtr{Cfloat},
                                                  batchCount::Cint, batchStride::Cint,
                                                  pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDgtsv2StridedBatch(handle, m, dl, d, du, x, batchCount,
                                             batchStride, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDgtsv2StridedBatch(handle::cusparseHandle_t, m::Cint,
                                                  dl::CuPtr{Cdouble}, d::CuPtr{Cdouble},
                                                  du::CuPtr{Cdouble}, x::CuPtr{Cdouble},
                                                  batchCount::Cint, batchStride::Cint,
                                                  pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCgtsv2StridedBatch(handle, m, dl, d, du, x, batchCount,
                                             batchStride, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCgtsv2StridedBatch(handle::cusparseHandle_t, m::Cint,
                                                  dl::CuPtr{cuComplex}, d::CuPtr{cuComplex},
                                                  du::CuPtr{cuComplex}, x::CuPtr{cuComplex},
                                                  batchCount::Cint, batchStride::Cint,
                                                  pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZgtsv2StridedBatch(handle, m, dl, d, du, x, batchCount,
                                             batchStride, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZgtsv2StridedBatch(handle::cusparseHandle_t, m::Cint,
                                                  dl::CuPtr{cuDoubleComplex},
                                                  d::CuPtr{cuDoubleComplex},
                                                  du::CuPtr{cuDoubleComplex},
                                                  x::CuPtr{cuDoubleComplex},
                                                  batchCount::Cint, batchStride::Cint,
                                                  pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSgtsvInterleavedBatch_bufferSizeExt(handle, algo, m, dl, d, du, x,
                                                              batchCount,
                                                              pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseSgtsvInterleavedBatch_bufferSizeExt(handle::cusparseHandle_t,
                                                                   algo::Cint, m::Cint,
                                                                   dl::CuPtr{Cfloat},
                                                                   d::CuPtr{Cfloat},
                                                                   du::CuPtr{Cfloat},
                                                                   x::CuPtr{Cfloat},
                                                                   batchCount::Cint,
                                                                   pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseDgtsvInterleavedBatch_bufferSizeExt(handle, algo, m, dl, d, du, x,
                                                              batchCount,
                                                              pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseDgtsvInterleavedBatch_bufferSizeExt(handle::cusparseHandle_t,
                                                                   algo::Cint, m::Cint,
                                                                   dl::CuPtr{Cdouble},
                                                                   d::CuPtr{Cdouble},
                                                                   du::CuPtr{Cdouble},
                                                                   x::CuPtr{Cdouble},
                                                                   batchCount::Cint,
                                                                   pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseCgtsvInterleavedBatch_bufferSizeExt(handle, algo, m, dl, d, du, x,
                                                              batchCount,
                                                              pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseCgtsvInterleavedBatch_bufferSizeExt(handle::cusparseHandle_t,
                                                                   algo::Cint, m::Cint,
                                                                   dl::CuPtr{cuComplex},
                                                                   d::CuPtr{cuComplex},
                                                                   du::CuPtr{cuComplex},
                                                                   x::CuPtr{cuComplex},
                                                                   batchCount::Cint,
                                                                   pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseZgtsvInterleavedBatch_bufferSizeExt(handle, algo, m, dl, d, du, x,
                                                              batchCount,
                                                              pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseZgtsvInterleavedBatch_bufferSizeExt(handle::cusparseHandle_t,
                                                                   algo::Cint, m::Cint,
                                                                   dl::CuPtr{cuDoubleComplex},
                                                                   d::CuPtr{cuDoubleComplex},
                                                                   du::CuPtr{cuDoubleComplex},
                                                                   x::CuPtr{cuDoubleComplex},
                                                                   batchCount::Cint,
                                                                   pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseSgtsvInterleavedBatch(handle, algo, m, dl, d, du, x, batchCount,
                                                pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSgtsvInterleavedBatch(handle::cusparseHandle_t, algo::Cint,
                                                     m::Cint, dl::CuPtr{Cfloat},
                                                     d::CuPtr{Cfloat}, du::CuPtr{Cfloat},
                                                     x::CuPtr{Cfloat}, batchCount::Cint,
                                                     pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDgtsvInterleavedBatch(handle, algo, m, dl, d, du, x, batchCount,
                                                pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDgtsvInterleavedBatch(handle::cusparseHandle_t, algo::Cint,
                                                     m::Cint, dl::CuPtr{Cdouble},
                                                     d::CuPtr{Cdouble}, du::CuPtr{Cdouble},
                                                     x::CuPtr{Cdouble}, batchCount::Cint,
                                                     pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCgtsvInterleavedBatch(handle, algo, m, dl, d, du, x, batchCount,
                                                pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCgtsvInterleavedBatch(handle::cusparseHandle_t, algo::Cint,
                                                     m::Cint, dl::CuPtr{cuComplex},
                                                     d::CuPtr{cuComplex},
                                                     du::CuPtr{cuComplex},
                                                     x::CuPtr{cuComplex}, batchCount::Cint,
                                                     pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZgtsvInterleavedBatch(handle, algo, m, dl, d, du, x, batchCount,
                                                pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZgtsvInterleavedBatch(handle::cusparseHandle_t, algo::Cint,
                                                     m::Cint, dl::CuPtr{cuDoubleComplex},
                                                     d::CuPtr{cuDoubleComplex},
                                                     du::CuPtr{cuDoubleComplex},
                                                     x::CuPtr{cuDoubleComplex},
                                                     batchCount::Cint,
                                                     pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSgpsvInterleavedBatch_bufferSizeExt(handle, algo, m, ds, dl, d,
                                                              du, dw, x, batchCount,
                                                              pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseSgpsvInterleavedBatch_bufferSizeExt(handle::cusparseHandle_t,
                                                                   algo::Cint, m::Cint,
                                                                   ds::CuPtr{Cfloat},
                                                                   dl::CuPtr{Cfloat},
                                                                   d::CuPtr{Cfloat},
                                                                   du::CuPtr{Cfloat},
                                                                   dw::CuPtr{Cfloat},
                                                                   x::CuPtr{Cfloat},
                                                                   batchCount::Cint,
                                                                   pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseDgpsvInterleavedBatch_bufferSizeExt(handle, algo, m, ds, dl, d,
                                                              du, dw, x, batchCount,
                                                              pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseDgpsvInterleavedBatch_bufferSizeExt(handle::cusparseHandle_t,
                                                                   algo::Cint, m::Cint,
                                                                   ds::CuPtr{Cdouble},
                                                                   dl::CuPtr{Cdouble},
                                                                   d::CuPtr{Cdouble},
                                                                   du::CuPtr{Cdouble},
                                                                   dw::CuPtr{Cdouble},
                                                                   x::CuPtr{Cdouble},
                                                                   batchCount::Cint,
                                                                   pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseCgpsvInterleavedBatch_bufferSizeExt(handle, algo, m, ds, dl, d,
                                                              du, dw, x, batchCount,
                                                              pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseCgpsvInterleavedBatch_bufferSizeExt(handle::cusparseHandle_t,
                                                                   algo::Cint, m::Cint,
                                                                   ds::CuPtr{cuComplex},
                                                                   dl::CuPtr{cuComplex},
                                                                   d::CuPtr{cuComplex},
                                                                   du::CuPtr{cuComplex},
                                                                   dw::CuPtr{cuComplex},
                                                                   x::CuPtr{cuComplex},
                                                                   batchCount::Cint,
                                                                   pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseZgpsvInterleavedBatch_bufferSizeExt(handle, algo, m, ds, dl, d,
                                                              du, dw, x, batchCount,
                                                              pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseZgpsvInterleavedBatch_bufferSizeExt(handle::cusparseHandle_t,
                                                                   algo::Cint, m::Cint,
                                                                   ds::CuPtr{cuDoubleComplex},
                                                                   dl::CuPtr{cuDoubleComplex},
                                                                   d::CuPtr{cuDoubleComplex},
                                                                   du::CuPtr{cuDoubleComplex},
                                                                   dw::CuPtr{cuDoubleComplex},
                                                                   x::CuPtr{cuDoubleComplex},
                                                                   batchCount::Cint,
                                                                   pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseSgpsvInterleavedBatch(handle, algo, m, ds, dl, d, du, dw, x,
                                                batchCount, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSgpsvInterleavedBatch(handle::cusparseHandle_t, algo::Cint,
                                                     m::Cint, ds::CuPtr{Cfloat},
                                                     dl::CuPtr{Cfloat}, d::CuPtr{Cfloat},
                                                     du::CuPtr{Cfloat}, dw::CuPtr{Cfloat},
                                                     x::CuPtr{Cfloat}, batchCount::Cint,
                                                     pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDgpsvInterleavedBatch(handle, algo, m, ds, dl, d, du, dw, x,
                                                batchCount, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDgpsvInterleavedBatch(handle::cusparseHandle_t, algo::Cint,
                                                     m::Cint, ds::CuPtr{Cdouble},
                                                     dl::CuPtr{Cdouble}, d::CuPtr{Cdouble},
                                                     du::CuPtr{Cdouble}, dw::CuPtr{Cdouble},
                                                     x::CuPtr{Cdouble}, batchCount::Cint,
                                                     pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCgpsvInterleavedBatch(handle, algo, m, ds, dl, d, du, dw, x,
                                                batchCount, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCgpsvInterleavedBatch(handle::cusparseHandle_t, algo::Cint,
                                                     m::Cint, ds::CuPtr{cuComplex},
                                                     dl::CuPtr{cuComplex},
                                                     d::CuPtr{cuComplex},
                                                     du::CuPtr{cuComplex},
                                                     dw::CuPtr{cuComplex},
                                                     x::CuPtr{cuComplex}, batchCount::Cint,
                                                     pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZgpsvInterleavedBatch(handle, algo, m, ds, dl, d, du, dw, x,
                                                batchCount, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZgpsvInterleavedBatch(handle::cusparseHandle_t, algo::Cint,
                                                     m::Cint, ds::CuPtr{cuDoubleComplex},
                                                     dl::CuPtr{cuDoubleComplex},
                                                     d::CuPtr{cuDoubleComplex},
                                                     du::CuPtr{cuDoubleComplex},
                                                     dw::CuPtr{cuDoubleComplex},
                                                     x::CuPtr{cuDoubleComplex},
                                                     batchCount::Cint,
                                                     pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCreateCsrgemm2Info(info)
    initialize_context()
    @ccall libcusparse.cusparseCreateCsrgemm2Info(info::Ptr{csrgemm2Info_t})::cusparseStatus_t
end

@checked function cusparseDestroyCsrgemm2Info(info)
    initialize_context()
    @ccall libcusparse.cusparseDestroyCsrgemm2Info(info::csrgemm2Info_t)::cusparseStatus_t
end

@checked function cusparseScsrgemm2_bufferSizeExt(handle, m, n, k, alpha, descrA, nnzA,
                                                  csrSortedRowPtrA, csrSortedColIndA,
                                                  descrB, nnzB, csrSortedRowPtrB,
                                                  csrSortedColIndB, beta, descrD, nnzD,
                                                  csrSortedRowPtrD, csrSortedColIndD, info,
                                                  pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseScsrgemm2_bufferSizeExt(handle::cusparseHandle_t, m::Cint,
                                                       n::Cint, k::Cint, alpha::Ref{Cfloat},
                                                       descrA::cusparseMatDescr_t,
                                                       nnzA::Cint,
                                                       csrSortedRowPtrA::CuPtr{Cint},
                                                       csrSortedColIndA::CuPtr{Cint},
                                                       descrB::cusparseMatDescr_t,
                                                       nnzB::Cint,
                                                       csrSortedRowPtrB::CuPtr{Cint},
                                                       csrSortedColIndB::CuPtr{Cint},
                                                       beta::Ref{Cfloat},
                                                       descrD::cusparseMatDescr_t,
                                                       nnzD::Cint,
                                                       csrSortedRowPtrD::CuPtr{Cint},
                                                       csrSortedColIndD::CuPtr{Cint},
                                                       info::csrgemm2Info_t,
                                                       pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseDcsrgemm2_bufferSizeExt(handle, m, n, k, alpha, descrA, nnzA,
                                                  csrSortedRowPtrA, csrSortedColIndA,
                                                  descrB, nnzB, csrSortedRowPtrB,
                                                  csrSortedColIndB, beta, descrD, nnzD,
                                                  csrSortedRowPtrD, csrSortedColIndD, info,
                                                  pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseDcsrgemm2_bufferSizeExt(handle::cusparseHandle_t, m::Cint,
                                                       n::Cint, k::Cint,
                                                       alpha::Ref{Cdouble},
                                                       descrA::cusparseMatDescr_t,
                                                       nnzA::Cint,
                                                       csrSortedRowPtrA::CuPtr{Cint},
                                                       csrSortedColIndA::CuPtr{Cint},
                                                       descrB::cusparseMatDescr_t,
                                                       nnzB::Cint,
                                                       csrSortedRowPtrB::CuPtr{Cint},
                                                       csrSortedColIndB::CuPtr{Cint},
                                                       beta::Ref{Cdouble},
                                                       descrD::cusparseMatDescr_t,
                                                       nnzD::Cint,
                                                       csrSortedRowPtrD::CuPtr{Cint},
                                                       csrSortedColIndD::CuPtr{Cint},
                                                       info::csrgemm2Info_t,
                                                       pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseCcsrgemm2_bufferSizeExt(handle, m, n, k, alpha, descrA, nnzA,
                                                  csrSortedRowPtrA, csrSortedColIndA,
                                                  descrB, nnzB, csrSortedRowPtrB,
                                                  csrSortedColIndB, beta, descrD, nnzD,
                                                  csrSortedRowPtrD, csrSortedColIndD, info,
                                                  pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseCcsrgemm2_bufferSizeExt(handle::cusparseHandle_t, m::Cint,
                                                       n::Cint, k::Cint,
                                                       alpha::Ref{cuComplex},
                                                       descrA::cusparseMatDescr_t,
                                                       nnzA::Cint,
                                                       csrSortedRowPtrA::CuPtr{Cint},
                                                       csrSortedColIndA::CuPtr{Cint},
                                                       descrB::cusparseMatDescr_t,
                                                       nnzB::Cint,
                                                       csrSortedRowPtrB::CuPtr{Cint},
                                                       csrSortedColIndB::CuPtr{Cint},
                                                       beta::Ref{cuComplex},
                                                       descrD::cusparseMatDescr_t,
                                                       nnzD::Cint,
                                                       csrSortedRowPtrD::CuPtr{Cint},
                                                       csrSortedColIndD::CuPtr{Cint},
                                                       info::csrgemm2Info_t,
                                                       pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseZcsrgemm2_bufferSizeExt(handle, m, n, k, alpha, descrA, nnzA,
                                                  csrSortedRowPtrA, csrSortedColIndA,
                                                  descrB, nnzB, csrSortedRowPtrB,
                                                  csrSortedColIndB, beta, descrD, nnzD,
                                                  csrSortedRowPtrD, csrSortedColIndD, info,
                                                  pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseZcsrgemm2_bufferSizeExt(handle::cusparseHandle_t, m::Cint,
                                                       n::Cint, k::Cint,
                                                       alpha::Ref{cuDoubleComplex},
                                                       descrA::cusparseMatDescr_t,
                                                       nnzA::Cint,
                                                       csrSortedRowPtrA::CuPtr{Cint},
                                                       csrSortedColIndA::CuPtr{Cint},
                                                       descrB::cusparseMatDescr_t,
                                                       nnzB::Cint,
                                                       csrSortedRowPtrB::CuPtr{Cint},
                                                       csrSortedColIndB::CuPtr{Cint},
                                                       beta::Ref{cuDoubleComplex},
                                                       descrD::cusparseMatDescr_t,
                                                       nnzD::Cint,
                                                       csrSortedRowPtrD::CuPtr{Cint},
                                                       csrSortedColIndD::CuPtr{Cint},
                                                       info::csrgemm2Info_t,
                                                       pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseXcsrgemm2Nnz(handle, m, n, k, descrA, nnzA, csrSortedRowPtrA,
                                       csrSortedColIndA, descrB, nnzB, csrSortedRowPtrB,
                                       csrSortedColIndB, descrD, nnzD, csrSortedRowPtrD,
                                       csrSortedColIndD, descrC, csrSortedRowPtrC,
                                       nnzTotalDevHostPtr, info, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseXcsrgemm2Nnz(handle::cusparseHandle_t, m::Cint, n::Cint,
                                            k::Cint, descrA::cusparseMatDescr_t, nnzA::Cint,
                                            csrSortedRowPtrA::CuPtr{Cint},
                                            csrSortedColIndA::CuPtr{Cint},
                                            descrB::cusparseMatDescr_t, nnzB::Cint,
                                            csrSortedRowPtrB::CuPtr{Cint},
                                            csrSortedColIndB::CuPtr{Cint},
                                            descrD::cusparseMatDescr_t, nnzD::Cint,
                                            csrSortedRowPtrD::CuPtr{Cint},
                                            csrSortedColIndD::CuPtr{Cint},
                                            descrC::cusparseMatDescr_t,
                                            csrSortedRowPtrC::CuPtr{Cint},
                                            nnzTotalDevHostPtr::PtrOrCuPtr{Cint},
                                            info::csrgemm2Info_t,
                                            pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseScsrgemm2(handle, m, n, k, alpha, descrA, nnzA, csrSortedValA,
                                    csrSortedRowPtrA, csrSortedColIndA, descrB, nnzB,
                                    csrSortedValB, csrSortedRowPtrB, csrSortedColIndB, beta,
                                    descrD, nnzD, csrSortedValD, csrSortedRowPtrD,
                                    csrSortedColIndD, descrC, csrSortedValC,
                                    csrSortedRowPtrC, csrSortedColIndC, info, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseScsrgemm2(handle::cusparseHandle_t, m::Cint, n::Cint,
                                         k::Cint, alpha::Ref{Cfloat},
                                         descrA::cusparseMatDescr_t, nnzA::Cint,
                                         csrSortedValA::CuPtr{Cfloat},
                                         csrSortedRowPtrA::CuPtr{Cint},
                                         csrSortedColIndA::CuPtr{Cint},
                                         descrB::cusparseMatDescr_t, nnzB::Cint,
                                         csrSortedValB::CuPtr{Cfloat},
                                         csrSortedRowPtrB::CuPtr{Cint},
                                         csrSortedColIndB::CuPtr{Cint}, beta::Ref{Cfloat},
                                         descrD::cusparseMatDescr_t, nnzD::Cint,
                                         csrSortedValD::CuPtr{Cfloat},
                                         csrSortedRowPtrD::CuPtr{Cint},
                                         csrSortedColIndD::CuPtr{Cint},
                                         descrC::cusparseMatDescr_t,
                                         csrSortedValC::CuPtr{Cfloat},
                                         csrSortedRowPtrC::CuPtr{Cint},
                                         csrSortedColIndC::CuPtr{Cint},
                                         info::csrgemm2Info_t,
                                         pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDcsrgemm2(handle, m, n, k, alpha, descrA, nnzA, csrSortedValA,
                                    csrSortedRowPtrA, csrSortedColIndA, descrB, nnzB,
                                    csrSortedValB, csrSortedRowPtrB, csrSortedColIndB, beta,
                                    descrD, nnzD, csrSortedValD, csrSortedRowPtrD,
                                    csrSortedColIndD, descrC, csrSortedValC,
                                    csrSortedRowPtrC, csrSortedColIndC, info, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDcsrgemm2(handle::cusparseHandle_t, m::Cint, n::Cint,
                                         k::Cint, alpha::Ref{Cdouble},
                                         descrA::cusparseMatDescr_t, nnzA::Cint,
                                         csrSortedValA::CuPtr{Cdouble},
                                         csrSortedRowPtrA::CuPtr{Cint},
                                         csrSortedColIndA::CuPtr{Cint},
                                         descrB::cusparseMatDescr_t, nnzB::Cint,
                                         csrSortedValB::CuPtr{Cdouble},
                                         csrSortedRowPtrB::CuPtr{Cint},
                                         csrSortedColIndB::CuPtr{Cint}, beta::Ref{Cdouble},
                                         descrD::cusparseMatDescr_t, nnzD::Cint,
                                         csrSortedValD::CuPtr{Cdouble},
                                         csrSortedRowPtrD::CuPtr{Cint},
                                         csrSortedColIndD::CuPtr{Cint},
                                         descrC::cusparseMatDescr_t,
                                         csrSortedValC::CuPtr{Cdouble},
                                         csrSortedRowPtrC::CuPtr{Cint},
                                         csrSortedColIndC::CuPtr{Cint},
                                         info::csrgemm2Info_t,
                                         pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCcsrgemm2(handle, m, n, k, alpha, descrA, nnzA, csrSortedValA,
                                    csrSortedRowPtrA, csrSortedColIndA, descrB, nnzB,
                                    csrSortedValB, csrSortedRowPtrB, csrSortedColIndB, beta,
                                    descrD, nnzD, csrSortedValD, csrSortedRowPtrD,
                                    csrSortedColIndD, descrC, csrSortedValC,
                                    csrSortedRowPtrC, csrSortedColIndC, info, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCcsrgemm2(handle::cusparseHandle_t, m::Cint, n::Cint,
                                         k::Cint, alpha::Ref{cuComplex},
                                         descrA::cusparseMatDescr_t, nnzA::Cint,
                                         csrSortedValA::CuPtr{cuComplex},
                                         csrSortedRowPtrA::CuPtr{Cint},
                                         csrSortedColIndA::CuPtr{Cint},
                                         descrB::cusparseMatDescr_t, nnzB::Cint,
                                         csrSortedValB::CuPtr{cuComplex},
                                         csrSortedRowPtrB::CuPtr{Cint},
                                         csrSortedColIndB::CuPtr{Cint},
                                         beta::Ref{cuComplex}, descrD::cusparseMatDescr_t,
                                         nnzD::Cint, csrSortedValD::CuPtr{cuComplex},
                                         csrSortedRowPtrD::CuPtr{Cint},
                                         csrSortedColIndD::CuPtr{Cint},
                                         descrC::cusparseMatDescr_t,
                                         csrSortedValC::CuPtr{cuComplex},
                                         csrSortedRowPtrC::CuPtr{Cint},
                                         csrSortedColIndC::CuPtr{Cint},
                                         info::csrgemm2Info_t,
                                         pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZcsrgemm2(handle, m, n, k, alpha, descrA, nnzA, csrSortedValA,
                                    csrSortedRowPtrA, csrSortedColIndA, descrB, nnzB,
                                    csrSortedValB, csrSortedRowPtrB, csrSortedColIndB, beta,
                                    descrD, nnzD, csrSortedValD, csrSortedRowPtrD,
                                    csrSortedColIndD, descrC, csrSortedValC,
                                    csrSortedRowPtrC, csrSortedColIndC, info, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZcsrgemm2(handle::cusparseHandle_t, m::Cint, n::Cint,
                                         k::Cint, alpha::Ref{cuDoubleComplex},
                                         descrA::cusparseMatDescr_t, nnzA::Cint,
                                         csrSortedValA::CuPtr{cuDoubleComplex},
                                         csrSortedRowPtrA::CuPtr{Cint},
                                         csrSortedColIndA::CuPtr{Cint},
                                         descrB::cusparseMatDescr_t, nnzB::Cint,
                                         csrSortedValB::CuPtr{cuDoubleComplex},
                                         csrSortedRowPtrB::CuPtr{Cint},
                                         csrSortedColIndB::CuPtr{Cint},
                                         beta::Ref{cuDoubleComplex},
                                         descrD::cusparseMatDescr_t, nnzD::Cint,
                                         csrSortedValD::CuPtr{cuDoubleComplex},
                                         csrSortedRowPtrD::CuPtr{Cint},
                                         csrSortedColIndD::CuPtr{Cint},
                                         descrC::cusparseMatDescr_t,
                                         csrSortedValC::CuPtr{cuDoubleComplex},
                                         csrSortedRowPtrC::CuPtr{Cint},
                                         csrSortedColIndC::CuPtr{Cint},
                                         info::csrgemm2Info_t,
                                         pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseScsrgeam2_bufferSizeExt(handle, m, n, alpha, descrA, nnzA,
                                                  csrSortedValA, csrSortedRowPtrA,
                                                  csrSortedColIndA, beta, descrB, nnzB,
                                                  csrSortedValB, csrSortedRowPtrB,
                                                  csrSortedColIndB, descrC, csrSortedValC,
                                                  csrSortedRowPtrC, csrSortedColIndC,
                                                  pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseScsrgeam2_bufferSizeExt(handle::cusparseHandle_t, m::Cint,
                                                       n::Cint, alpha::Ref{Cfloat},
                                                       descrA::cusparseMatDescr_t,
                                                       nnzA::Cint,
                                                       csrSortedValA::CuPtr{Cfloat},
                                                       csrSortedRowPtrA::CuPtr{Cint},
                                                       csrSortedColIndA::CuPtr{Cint},
                                                       beta::Ref{Cfloat},
                                                       descrB::cusparseMatDescr_t,
                                                       nnzB::Cint,
                                                       csrSortedValB::CuPtr{Cfloat},
                                                       csrSortedRowPtrB::CuPtr{Cint},
                                                       csrSortedColIndB::CuPtr{Cint},
                                                       descrC::cusparseMatDescr_t,
                                                       csrSortedValC::CuPtr{Cfloat},
                                                       csrSortedRowPtrC::CuPtr{Cint},
                                                       csrSortedColIndC::CuPtr{Cint},
                                                       pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseDcsrgeam2_bufferSizeExt(handle, m, n, alpha, descrA, nnzA,
                                                  csrSortedValA, csrSortedRowPtrA,
                                                  csrSortedColIndA, beta, descrB, nnzB,
                                                  csrSortedValB, csrSortedRowPtrB,
                                                  csrSortedColIndB, descrC, csrSortedValC,
                                                  csrSortedRowPtrC, csrSortedColIndC,
                                                  pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseDcsrgeam2_bufferSizeExt(handle::cusparseHandle_t, m::Cint,
                                                       n::Cint, alpha::Ref{Cdouble},
                                                       descrA::cusparseMatDescr_t,
                                                       nnzA::Cint,
                                                       csrSortedValA::CuPtr{Cdouble},
                                                       csrSortedRowPtrA::CuPtr{Cint},
                                                       csrSortedColIndA::CuPtr{Cint},
                                                       beta::Ref{Cdouble},
                                                       descrB::cusparseMatDescr_t,
                                                       nnzB::Cint,
                                                       csrSortedValB::CuPtr{Cdouble},
                                                       csrSortedRowPtrB::CuPtr{Cint},
                                                       csrSortedColIndB::CuPtr{Cint},
                                                       descrC::cusparseMatDescr_t,
                                                       csrSortedValC::CuPtr{Cdouble},
                                                       csrSortedRowPtrC::CuPtr{Cint},
                                                       csrSortedColIndC::CuPtr{Cint},
                                                       pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseCcsrgeam2_bufferSizeExt(handle, m, n, alpha, descrA, nnzA,
                                                  csrSortedValA, csrSortedRowPtrA,
                                                  csrSortedColIndA, beta, descrB, nnzB,
                                                  csrSortedValB, csrSortedRowPtrB,
                                                  csrSortedColIndB, descrC, csrSortedValC,
                                                  csrSortedRowPtrC, csrSortedColIndC,
                                                  pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseCcsrgeam2_bufferSizeExt(handle::cusparseHandle_t, m::Cint,
                                                       n::Cint, alpha::Ref{cuComplex},
                                                       descrA::cusparseMatDescr_t,
                                                       nnzA::Cint,
                                                       csrSortedValA::CuPtr{cuComplex},
                                                       csrSortedRowPtrA::CuPtr{Cint},
                                                       csrSortedColIndA::CuPtr{Cint},
                                                       beta::Ref{cuComplex},
                                                       descrB::cusparseMatDescr_t,
                                                       nnzB::Cint,
                                                       csrSortedValB::CuPtr{cuComplex},
                                                       csrSortedRowPtrB::CuPtr{Cint},
                                                       csrSortedColIndB::CuPtr{Cint},
                                                       descrC::cusparseMatDescr_t,
                                                       csrSortedValC::CuPtr{cuComplex},
                                                       csrSortedRowPtrC::CuPtr{Cint},
                                                       csrSortedColIndC::CuPtr{Cint},
                                                       pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseZcsrgeam2_bufferSizeExt(handle, m, n, alpha, descrA, nnzA,
                                                  csrSortedValA, csrSortedRowPtrA,
                                                  csrSortedColIndA, beta, descrB, nnzB,
                                                  csrSortedValB, csrSortedRowPtrB,
                                                  csrSortedColIndB, descrC, csrSortedValC,
                                                  csrSortedRowPtrC, csrSortedColIndC,
                                                  pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseZcsrgeam2_bufferSizeExt(handle::cusparseHandle_t, m::Cint,
                                                       n::Cint, alpha::Ref{cuDoubleComplex},
                                                       descrA::cusparseMatDescr_t,
                                                       nnzA::Cint,
                                                       csrSortedValA::CuPtr{cuDoubleComplex},
                                                       csrSortedRowPtrA::CuPtr{Cint},
                                                       csrSortedColIndA::CuPtr{Cint},
                                                       beta::Ref{cuDoubleComplex},
                                                       descrB::cusparseMatDescr_t,
                                                       nnzB::Cint,
                                                       csrSortedValB::CuPtr{cuDoubleComplex},
                                                       csrSortedRowPtrB::CuPtr{Cint},
                                                       csrSortedColIndB::CuPtr{Cint},
                                                       descrC::cusparseMatDescr_t,
                                                       csrSortedValC::CuPtr{cuDoubleComplex},
                                                       csrSortedRowPtrC::CuPtr{Cint},
                                                       csrSortedColIndC::CuPtr{Cint},
                                                       pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseXcsrgeam2Nnz(handle, m, n, descrA, nnzA, csrSortedRowPtrA,
                                       csrSortedColIndA, descrB, nnzB, csrSortedRowPtrB,
                                       csrSortedColIndB, descrC, csrSortedRowPtrC,
                                       nnzTotalDevHostPtr, workspace)
    initialize_context()
    @ccall libcusparse.cusparseXcsrgeam2Nnz(handle::cusparseHandle_t, m::Cint, n::Cint,
                                            descrA::cusparseMatDescr_t, nnzA::Cint,
                                            csrSortedRowPtrA::CuPtr{Cint},
                                            csrSortedColIndA::CuPtr{Cint},
                                            descrB::cusparseMatDescr_t, nnzB::Cint,
                                            csrSortedRowPtrB::CuPtr{Cint},
                                            csrSortedColIndB::CuPtr{Cint},
                                            descrC::cusparseMatDescr_t,
                                            csrSortedRowPtrC::CuPtr{Cint},
                                            nnzTotalDevHostPtr::PtrOrCuPtr{Cint},
                                            workspace::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseScsrgeam2(handle, m, n, alpha, descrA, nnzA, csrSortedValA,
                                    csrSortedRowPtrA, csrSortedColIndA, beta, descrB, nnzB,
                                    csrSortedValB, csrSortedRowPtrB, csrSortedColIndB,
                                    descrC, csrSortedValC, csrSortedRowPtrC,
                                    csrSortedColIndC, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseScsrgeam2(handle::cusparseHandle_t, m::Cint, n::Cint,
                                         alpha::Ref{Cfloat}, descrA::cusparseMatDescr_t,
                                         nnzA::Cint, csrSortedValA::CuPtr{Cfloat},
                                         csrSortedRowPtrA::CuPtr{Cint},
                                         csrSortedColIndA::CuPtr{Cint}, beta::Ref{Cfloat},
                                         descrB::cusparseMatDescr_t, nnzB::Cint,
                                         csrSortedValB::CuPtr{Cfloat},
                                         csrSortedRowPtrB::CuPtr{Cint},
                                         csrSortedColIndB::CuPtr{Cint},
                                         descrC::cusparseMatDescr_t,
                                         csrSortedValC::CuPtr{Cfloat},
                                         csrSortedRowPtrC::CuPtr{Cint},
                                         csrSortedColIndC::CuPtr{Cint},
                                         pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDcsrgeam2(handle, m, n, alpha, descrA, nnzA, csrSortedValA,
                                    csrSortedRowPtrA, csrSortedColIndA, beta, descrB, nnzB,
                                    csrSortedValB, csrSortedRowPtrB, csrSortedColIndB,
                                    descrC, csrSortedValC, csrSortedRowPtrC,
                                    csrSortedColIndC, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDcsrgeam2(handle::cusparseHandle_t, m::Cint, n::Cint,
                                         alpha::Ref{Cdouble}, descrA::cusparseMatDescr_t,
                                         nnzA::Cint, csrSortedValA::CuPtr{Cdouble},
                                         csrSortedRowPtrA::CuPtr{Cint},
                                         csrSortedColIndA::CuPtr{Cint}, beta::Ref{Cdouble},
                                         descrB::cusparseMatDescr_t, nnzB::Cint,
                                         csrSortedValB::CuPtr{Cdouble},
                                         csrSortedRowPtrB::CuPtr{Cint},
                                         csrSortedColIndB::CuPtr{Cint},
                                         descrC::cusparseMatDescr_t,
                                         csrSortedValC::CuPtr{Cdouble},
                                         csrSortedRowPtrC::CuPtr{Cint},
                                         csrSortedColIndC::CuPtr{Cint},
                                         pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCcsrgeam2(handle, m, n, alpha, descrA, nnzA, csrSortedValA,
                                    csrSortedRowPtrA, csrSortedColIndA, beta, descrB, nnzB,
                                    csrSortedValB, csrSortedRowPtrB, csrSortedColIndB,
                                    descrC, csrSortedValC, csrSortedRowPtrC,
                                    csrSortedColIndC, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCcsrgeam2(handle::cusparseHandle_t, m::Cint, n::Cint,
                                         alpha::Ref{cuComplex}, descrA::cusparseMatDescr_t,
                                         nnzA::Cint, csrSortedValA::CuPtr{cuComplex},
                                         csrSortedRowPtrA::CuPtr{Cint},
                                         csrSortedColIndA::CuPtr{Cint},
                                         beta::Ref{cuComplex}, descrB::cusparseMatDescr_t,
                                         nnzB::Cint, csrSortedValB::CuPtr{cuComplex},
                                         csrSortedRowPtrB::CuPtr{Cint},
                                         csrSortedColIndB::CuPtr{Cint},
                                         descrC::cusparseMatDescr_t,
                                         csrSortedValC::CuPtr{cuComplex},
                                         csrSortedRowPtrC::CuPtr{Cint},
                                         csrSortedColIndC::CuPtr{Cint},
                                         pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZcsrgeam2(handle, m, n, alpha, descrA, nnzA, csrSortedValA,
                                    csrSortedRowPtrA, csrSortedColIndA, beta, descrB, nnzB,
                                    csrSortedValB, csrSortedRowPtrB, csrSortedColIndB,
                                    descrC, csrSortedValC, csrSortedRowPtrC,
                                    csrSortedColIndC, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZcsrgeam2(handle::cusparseHandle_t, m::Cint, n::Cint,
                                         alpha::Ref{cuDoubleComplex},
                                         descrA::cusparseMatDescr_t, nnzA::Cint,
                                         csrSortedValA::CuPtr{cuDoubleComplex},
                                         csrSortedRowPtrA::CuPtr{Cint},
                                         csrSortedColIndA::CuPtr{Cint},
                                         beta::Ref{cuDoubleComplex},
                                         descrB::cusparseMatDescr_t, nnzB::Cint,
                                         csrSortedValB::CuPtr{cuDoubleComplex},
                                         csrSortedRowPtrB::CuPtr{Cint},
                                         csrSortedColIndB::CuPtr{Cint},
                                         descrC::cusparseMatDescr_t,
                                         csrSortedValC::CuPtr{cuDoubleComplex},
                                         csrSortedRowPtrC::CuPtr{Cint},
                                         csrSortedColIndC::CuPtr{Cint},
                                         pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseScsrcolor(handle, m, nnz, descrA, csrSortedValA, csrSortedRowPtrA,
                                    csrSortedColIndA, fractionToColor, ncolors, coloring,
                                    reordering, info)
    initialize_context()
    @ccall libcusparse.cusparseScsrcolor(handle::cusparseHandle_t, m::Cint, nnz::Cint,
                                         descrA::cusparseMatDescr_t,
                                         csrSortedValA::CuPtr{Cfloat},
                                         csrSortedRowPtrA::CuPtr{Cint},
                                         csrSortedColIndA::CuPtr{Cint},
                                         fractionToColor::Ptr{Cfloat}, ncolors::Ptr{Cint},
                                         coloring::CuPtr{Cint}, reordering::CuPtr{Cint},
                                         info::cusparseColorInfo_t)::cusparseStatus_t
end

@checked function cusparseDcsrcolor(handle, m, nnz, descrA, csrSortedValA, csrSortedRowPtrA,
                                    csrSortedColIndA, fractionToColor, ncolors, coloring,
                                    reordering, info)
    initialize_context()
    @ccall libcusparse.cusparseDcsrcolor(handle::cusparseHandle_t, m::Cint, nnz::Cint,
                                         descrA::cusparseMatDescr_t,
                                         csrSortedValA::CuPtr{Cdouble},
                                         csrSortedRowPtrA::CuPtr{Cint},
                                         csrSortedColIndA::CuPtr{Cint},
                                         fractionToColor::Ptr{Cdouble}, ncolors::Ptr{Cint},
                                         coloring::CuPtr{Cint}, reordering::CuPtr{Cint},
                                         info::cusparseColorInfo_t)::cusparseStatus_t
end

@checked function cusparseCcsrcolor(handle, m, nnz, descrA, csrSortedValA, csrSortedRowPtrA,
                                    csrSortedColIndA, fractionToColor, ncolors, coloring,
                                    reordering, info)
    initialize_context()
    @ccall libcusparse.cusparseCcsrcolor(handle::cusparseHandle_t, m::Cint, nnz::Cint,
                                         descrA::cusparseMatDescr_t,
                                         csrSortedValA::CuPtr{cuComplex},
                                         csrSortedRowPtrA::CuPtr{Cint},
                                         csrSortedColIndA::CuPtr{Cint},
                                         fractionToColor::Ptr{Cfloat}, ncolors::Ptr{Cint},
                                         coloring::CuPtr{Cint}, reordering::CuPtr{Cint},
                                         info::cusparseColorInfo_t)::cusparseStatus_t
end

@checked function cusparseZcsrcolor(handle, m, nnz, descrA, csrSortedValA, csrSortedRowPtrA,
                                    csrSortedColIndA, fractionToColor, ncolors, coloring,
                                    reordering, info)
    initialize_context()
    @ccall libcusparse.cusparseZcsrcolor(handle::cusparseHandle_t, m::Cint, nnz::Cint,
                                         descrA::cusparseMatDescr_t,
                                         csrSortedValA::CuPtr{cuDoubleComplex},
                                         csrSortedRowPtrA::CuPtr{Cint},
                                         csrSortedColIndA::CuPtr{Cint},
                                         fractionToColor::Ptr{Cdouble}, ncolors::Ptr{Cint},
                                         coloring::CuPtr{Cint}, reordering::CuPtr{Cint},
                                         info::cusparseColorInfo_t)::cusparseStatus_t
end

@checked function cusparseSnnz(handle, dirA, m, n, descrA, A, lda, nnzPerRowCol,
                               nnzTotalDevHostPtr)
    initialize_context()
    @ccall libcusparse.cusparseSnnz(handle::cusparseHandle_t, dirA::cusparseDirection_t,
                                    m::Cint, n::Cint, descrA::cusparseMatDescr_t,
                                    A::CuPtr{Cfloat}, lda::Cint, nnzPerRowCol::CuPtr{Cint},
                                    nnzTotalDevHostPtr::PtrOrCuPtr{Cint})::cusparseStatus_t
end

@checked function cusparseDnnz(handle, dirA, m, n, descrA, A, lda, nnzPerRowCol,
                               nnzTotalDevHostPtr)
    initialize_context()
    @ccall libcusparse.cusparseDnnz(handle::cusparseHandle_t, dirA::cusparseDirection_t,
                                    m::Cint, n::Cint, descrA::cusparseMatDescr_t,
                                    A::CuPtr{Cdouble}, lda::Cint, nnzPerRowCol::CuPtr{Cint},
                                    nnzTotalDevHostPtr::PtrOrCuPtr{Cint})::cusparseStatus_t
end

@checked function cusparseCnnz(handle, dirA, m, n, descrA, A, lda, nnzPerRowCol,
                               nnzTotalDevHostPtr)
    initialize_context()
    @ccall libcusparse.cusparseCnnz(handle::cusparseHandle_t, dirA::cusparseDirection_t,
                                    m::Cint, n::Cint, descrA::cusparseMatDescr_t,
                                    A::CuPtr{cuComplex}, lda::Cint,
                                    nnzPerRowCol::CuPtr{Cint},
                                    nnzTotalDevHostPtr::PtrOrCuPtr{Cint})::cusparseStatus_t
end

@checked function cusparseZnnz(handle, dirA, m, n, descrA, A, lda, nnzPerRowCol,
                               nnzTotalDevHostPtr)
    initialize_context()
    @ccall libcusparse.cusparseZnnz(handle::cusparseHandle_t, dirA::cusparseDirection_t,
                                    m::Cint, n::Cint, descrA::cusparseMatDescr_t,
                                    A::CuPtr{cuDoubleComplex}, lda::Cint,
                                    nnzPerRowCol::CuPtr{Cint},
                                    nnzTotalDevHostPtr::PtrOrCuPtr{Cint})::cusparseStatus_t
end

@checked function cusparseSnnz_compress(handle, m, descr, csrSortedValA, csrSortedRowPtrA,
                                        nnzPerRow, nnzC, tol)
    initialize_context()
    @ccall libcusparse.cusparseSnnz_compress(handle::cusparseHandle_t, m::Cint,
                                             descr::cusparseMatDescr_t,
                                             csrSortedValA::CuPtr{Cfloat},
                                             csrSortedRowPtrA::CuPtr{Cint},
                                             nnzPerRow::CuPtr{Cint}, nnzC::PtrOrCuPtr{Cint},
                                             tol::Cfloat)::cusparseStatus_t
end

@checked function cusparseDnnz_compress(handle, m, descr, csrSortedValA, csrSortedRowPtrA,
                                        nnzPerRow, nnzC, tol)
    initialize_context()
    @ccall libcusparse.cusparseDnnz_compress(handle::cusparseHandle_t, m::Cint,
                                             descr::cusparseMatDescr_t,
                                             csrSortedValA::CuPtr{Cdouble},
                                             csrSortedRowPtrA::CuPtr{Cint},
                                             nnzPerRow::CuPtr{Cint}, nnzC::PtrOrCuPtr{Cint},
                                             tol::Cdouble)::cusparseStatus_t
end

@checked function cusparseCnnz_compress(handle, m, descr, csrSortedValA, csrSortedRowPtrA,
                                        nnzPerRow, nnzC, tol)
    initialize_context()
    @ccall libcusparse.cusparseCnnz_compress(handle::cusparseHandle_t, m::Cint,
                                             descr::cusparseMatDescr_t,
                                             csrSortedValA::CuPtr{cuComplex},
                                             csrSortedRowPtrA::CuPtr{Cint},
                                             nnzPerRow::CuPtr{Cint}, nnzC::PtrOrCuPtr{Cint},
                                             tol::cuComplex)::cusparseStatus_t
end

@checked function cusparseZnnz_compress(handle, m, descr, csrSortedValA, csrSortedRowPtrA,
                                        nnzPerRow, nnzC, tol)
    initialize_context()
    @ccall libcusparse.cusparseZnnz_compress(handle::cusparseHandle_t, m::Cint,
                                             descr::cusparseMatDescr_t,
                                             csrSortedValA::CuPtr{cuDoubleComplex},
                                             csrSortedRowPtrA::CuPtr{Cint},
                                             nnzPerRow::CuPtr{Cint}, nnzC::PtrOrCuPtr{Cint},
                                             tol::cuDoubleComplex)::cusparseStatus_t
end

@checked function cusparseScsr2csr_compress(handle, m, n, descrA, csrSortedValA,
                                            csrSortedColIndA, csrSortedRowPtrA, nnzA,
                                            nnzPerRow, csrSortedValC, csrSortedColIndC,
                                            csrSortedRowPtrC, tol)
    initialize_context()
    @ccall libcusparse.cusparseScsr2csr_compress(handle::cusparseHandle_t, m::Cint, n::Cint,
                                                 descrA::cusparseMatDescr_t,
                                                 csrSortedValA::CuPtr{Cfloat},
                                                 csrSortedColIndA::CuPtr{Cint},
                                                 csrSortedRowPtrA::CuPtr{Cint}, nnzA::Cint,
                                                 nnzPerRow::CuPtr{Cint},
                                                 csrSortedValC::CuPtr{Cfloat},
                                                 csrSortedColIndC::CuPtr{Cint},
                                                 csrSortedRowPtrC::CuPtr{Cint},
                                                 tol::Cfloat)::cusparseStatus_t
end

@checked function cusparseDcsr2csr_compress(handle, m, n, descrA, csrSortedValA,
                                            csrSortedColIndA, csrSortedRowPtrA, nnzA,
                                            nnzPerRow, csrSortedValC, csrSortedColIndC,
                                            csrSortedRowPtrC, tol)
    initialize_context()
    @ccall libcusparse.cusparseDcsr2csr_compress(handle::cusparseHandle_t, m::Cint, n::Cint,
                                                 descrA::cusparseMatDescr_t,
                                                 csrSortedValA::CuPtr{Cdouble},
                                                 csrSortedColIndA::CuPtr{Cint},
                                                 csrSortedRowPtrA::CuPtr{Cint}, nnzA::Cint,
                                                 nnzPerRow::CuPtr{Cint},
                                                 csrSortedValC::CuPtr{Cdouble},
                                                 csrSortedColIndC::CuPtr{Cint},
                                                 csrSortedRowPtrC::CuPtr{Cint},
                                                 tol::Cdouble)::cusparseStatus_t
end

@checked function cusparseCcsr2csr_compress(handle, m, n, descrA, csrSortedValA,
                                            csrSortedColIndA, csrSortedRowPtrA, nnzA,
                                            nnzPerRow, csrSortedValC, csrSortedColIndC,
                                            csrSortedRowPtrC, tol)
    initialize_context()
    @ccall libcusparse.cusparseCcsr2csr_compress(handle::cusparseHandle_t, m::Cint, n::Cint,
                                                 descrA::cusparseMatDescr_t,
                                                 csrSortedValA::CuPtr{cuComplex},
                                                 csrSortedColIndA::CuPtr{Cint},
                                                 csrSortedRowPtrA::CuPtr{Cint}, nnzA::Cint,
                                                 nnzPerRow::CuPtr{Cint},
                                                 csrSortedValC::CuPtr{cuComplex},
                                                 csrSortedColIndC::CuPtr{Cint},
                                                 csrSortedRowPtrC::CuPtr{Cint},
                                                 tol::cuComplex)::cusparseStatus_t
end

@checked function cusparseZcsr2csr_compress(handle, m, n, descrA, csrSortedValA,
                                            csrSortedColIndA, csrSortedRowPtrA, nnzA,
                                            nnzPerRow, csrSortedValC, csrSortedColIndC,
                                            csrSortedRowPtrC, tol)
    initialize_context()
    @ccall libcusparse.cusparseZcsr2csr_compress(handle::cusparseHandle_t, m::Cint, n::Cint,
                                                 descrA::cusparseMatDescr_t,
                                                 csrSortedValA::CuPtr{cuDoubleComplex},
                                                 csrSortedColIndA::CuPtr{Cint},
                                                 csrSortedRowPtrA::CuPtr{Cint}, nnzA::Cint,
                                                 nnzPerRow::CuPtr{Cint},
                                                 csrSortedValC::CuPtr{cuDoubleComplex},
                                                 csrSortedColIndC::CuPtr{Cint},
                                                 csrSortedRowPtrC::CuPtr{Cint},
                                                 tol::cuDoubleComplex)::cusparseStatus_t
end

@checked function cusparseSdense2csr(handle, m, n, descrA, A, lda, nnzPerRow, csrSortedValA,
                                     csrSortedRowPtrA, csrSortedColIndA)
    initialize_context()
    @ccall libcusparse.cusparseSdense2csr(handle::cusparseHandle_t, m::Cint, n::Cint,
                                          descrA::cusparseMatDescr_t, A::CuPtr{Cfloat},
                                          lda::Cint, nnzPerRow::CuPtr{Cint},
                                          csrSortedValA::CuPtr{Cfloat},
                                          csrSortedRowPtrA::CuPtr{Cint},
                                          csrSortedColIndA::CuPtr{Cint})::cusparseStatus_t
end

@checked function cusparseDdense2csr(handle, m, n, descrA, A, lda, nnzPerRow, csrSortedValA,
                                     csrSortedRowPtrA, csrSortedColIndA)
    initialize_context()
    @ccall libcusparse.cusparseDdense2csr(handle::cusparseHandle_t, m::Cint, n::Cint,
                                          descrA::cusparseMatDescr_t, A::CuPtr{Cdouble},
                                          lda::Cint, nnzPerRow::CuPtr{Cint},
                                          csrSortedValA::CuPtr{Cdouble},
                                          csrSortedRowPtrA::CuPtr{Cint},
                                          csrSortedColIndA::CuPtr{Cint})::cusparseStatus_t
end

@checked function cusparseCdense2csr(handle, m, n, descrA, A, lda, nnzPerRow, csrSortedValA,
                                     csrSortedRowPtrA, csrSortedColIndA)
    initialize_context()
    @ccall libcusparse.cusparseCdense2csr(handle::cusparseHandle_t, m::Cint, n::Cint,
                                          descrA::cusparseMatDescr_t, A::CuPtr{cuComplex},
                                          lda::Cint, nnzPerRow::CuPtr{Cint},
                                          csrSortedValA::CuPtr{cuComplex},
                                          csrSortedRowPtrA::CuPtr{Cint},
                                          csrSortedColIndA::CuPtr{Cint})::cusparseStatus_t
end

@checked function cusparseZdense2csr(handle, m, n, descrA, A, lda, nnzPerRow, csrSortedValA,
                                     csrSortedRowPtrA, csrSortedColIndA)
    initialize_context()
    @ccall libcusparse.cusparseZdense2csr(handle::cusparseHandle_t, m::Cint, n::Cint,
                                          descrA::cusparseMatDescr_t,
                                          A::CuPtr{cuDoubleComplex}, lda::Cint,
                                          nnzPerRow::CuPtr{Cint},
                                          csrSortedValA::CuPtr{cuDoubleComplex},
                                          csrSortedRowPtrA::CuPtr{Cint},
                                          csrSortedColIndA::CuPtr{Cint})::cusparseStatus_t
end

@checked function cusparseScsr2dense(handle, m, n, descrA, csrSortedValA, csrSortedRowPtrA,
                                     csrSortedColIndA, A, lda)
    initialize_context()
    @ccall libcusparse.cusparseScsr2dense(handle::cusparseHandle_t, m::Cint, n::Cint,
                                          descrA::cusparseMatDescr_t,
                                          csrSortedValA::CuPtr{Cfloat},
                                          csrSortedRowPtrA::CuPtr{Cint},
                                          csrSortedColIndA::CuPtr{Cint}, A::CuPtr{Cfloat},
                                          lda::Cint)::cusparseStatus_t
end

@checked function cusparseDcsr2dense(handle, m, n, descrA, csrSortedValA, csrSortedRowPtrA,
                                     csrSortedColIndA, A, lda)
    initialize_context()
    @ccall libcusparse.cusparseDcsr2dense(handle::cusparseHandle_t, m::Cint, n::Cint,
                                          descrA::cusparseMatDescr_t,
                                          csrSortedValA::CuPtr{Cdouble},
                                          csrSortedRowPtrA::CuPtr{Cint},
                                          csrSortedColIndA::CuPtr{Cint}, A::CuPtr{Cdouble},
                                          lda::Cint)::cusparseStatus_t
end

@checked function cusparseCcsr2dense(handle, m, n, descrA, csrSortedValA, csrSortedRowPtrA,
                                     csrSortedColIndA, A, lda)
    initialize_context()
    @ccall libcusparse.cusparseCcsr2dense(handle::cusparseHandle_t, m::Cint, n::Cint,
                                          descrA::cusparseMatDescr_t,
                                          csrSortedValA::CuPtr{cuComplex},
                                          csrSortedRowPtrA::CuPtr{Cint},
                                          csrSortedColIndA::CuPtr{Cint},
                                          A::CuPtr{cuComplex}, lda::Cint)::cusparseStatus_t
end

@checked function cusparseZcsr2dense(handle, m, n, descrA, csrSortedValA, csrSortedRowPtrA,
                                     csrSortedColIndA, A, lda)
    initialize_context()
    @ccall libcusparse.cusparseZcsr2dense(handle::cusparseHandle_t, m::Cint, n::Cint,
                                          descrA::cusparseMatDescr_t,
                                          csrSortedValA::CuPtr{cuDoubleComplex},
                                          csrSortedRowPtrA::CuPtr{Cint},
                                          csrSortedColIndA::CuPtr{Cint},
                                          A::CuPtr{cuDoubleComplex},
                                          lda::Cint)::cusparseStatus_t
end

@checked function cusparseSdense2csc(handle, m, n, descrA, A, lda, nnzPerCol, cscSortedValA,
                                     cscSortedRowIndA, cscSortedColPtrA)
    initialize_context()
    @ccall libcusparse.cusparseSdense2csc(handle::cusparseHandle_t, m::Cint, n::Cint,
                                          descrA::cusparseMatDescr_t, A::CuPtr{Cfloat},
                                          lda::Cint, nnzPerCol::CuPtr{Cint},
                                          cscSortedValA::CuPtr{Cfloat},
                                          cscSortedRowIndA::CuPtr{Cint},
                                          cscSortedColPtrA::CuPtr{Cint})::cusparseStatus_t
end

@checked function cusparseDdense2csc(handle, m, n, descrA, A, lda, nnzPerCol, cscSortedValA,
                                     cscSortedRowIndA, cscSortedColPtrA)
    initialize_context()
    @ccall libcusparse.cusparseDdense2csc(handle::cusparseHandle_t, m::Cint, n::Cint,
                                          descrA::cusparseMatDescr_t, A::CuPtr{Cdouble},
                                          lda::Cint, nnzPerCol::CuPtr{Cint},
                                          cscSortedValA::CuPtr{Cdouble},
                                          cscSortedRowIndA::CuPtr{Cint},
                                          cscSortedColPtrA::CuPtr{Cint})::cusparseStatus_t
end

@checked function cusparseCdense2csc(handle, m, n, descrA, A, lda, nnzPerCol, cscSortedValA,
                                     cscSortedRowIndA, cscSortedColPtrA)
    initialize_context()
    @ccall libcusparse.cusparseCdense2csc(handle::cusparseHandle_t, m::Cint, n::Cint,
                                          descrA::cusparseMatDescr_t, A::CuPtr{cuComplex},
                                          lda::Cint, nnzPerCol::CuPtr{Cint},
                                          cscSortedValA::CuPtr{cuComplex},
                                          cscSortedRowIndA::CuPtr{Cint},
                                          cscSortedColPtrA::CuPtr{Cint})::cusparseStatus_t
end

@checked function cusparseZdense2csc(handle, m, n, descrA, A, lda, nnzPerCol, cscSortedValA,
                                     cscSortedRowIndA, cscSortedColPtrA)
    initialize_context()
    @ccall libcusparse.cusparseZdense2csc(handle::cusparseHandle_t, m::Cint, n::Cint,
                                          descrA::cusparseMatDescr_t,
                                          A::CuPtr{cuDoubleComplex}, lda::Cint,
                                          nnzPerCol::CuPtr{Cint},
                                          cscSortedValA::CuPtr{cuDoubleComplex},
                                          cscSortedRowIndA::CuPtr{Cint},
                                          cscSortedColPtrA::CuPtr{Cint})::cusparseStatus_t
end

@checked function cusparseScsc2dense(handle, m, n, descrA, cscSortedValA, cscSortedRowIndA,
                                     cscSortedColPtrA, A, lda)
    initialize_context()
    @ccall libcusparse.cusparseScsc2dense(handle::cusparseHandle_t, m::Cint, n::Cint,
                                          descrA::cusparseMatDescr_t,
                                          cscSortedValA::CuPtr{Cfloat},
                                          cscSortedRowIndA::CuPtr{Cint},
                                          cscSortedColPtrA::CuPtr{Cint}, A::CuPtr{Cfloat},
                                          lda::Cint)::cusparseStatus_t
end

@checked function cusparseDcsc2dense(handle, m, n, descrA, cscSortedValA, cscSortedRowIndA,
                                     cscSortedColPtrA, A, lda)
    initialize_context()
    @ccall libcusparse.cusparseDcsc2dense(handle::cusparseHandle_t, m::Cint, n::Cint,
                                          descrA::cusparseMatDescr_t,
                                          cscSortedValA::CuPtr{Cdouble},
                                          cscSortedRowIndA::CuPtr{Cint},
                                          cscSortedColPtrA::CuPtr{Cint}, A::CuPtr{Cdouble},
                                          lda::Cint)::cusparseStatus_t
end

@checked function cusparseCcsc2dense(handle, m, n, descrA, cscSortedValA, cscSortedRowIndA,
                                     cscSortedColPtrA, A, lda)
    initialize_context()
    @ccall libcusparse.cusparseCcsc2dense(handle::cusparseHandle_t, m::Cint, n::Cint,
                                          descrA::cusparseMatDescr_t,
                                          cscSortedValA::CuPtr{cuComplex},
                                          cscSortedRowIndA::CuPtr{Cint},
                                          cscSortedColPtrA::CuPtr{Cint},
                                          A::CuPtr{cuComplex}, lda::Cint)::cusparseStatus_t
end

@checked function cusparseZcsc2dense(handle, m, n, descrA, cscSortedValA, cscSortedRowIndA,
                                     cscSortedColPtrA, A, lda)
    initialize_context()
    @ccall libcusparse.cusparseZcsc2dense(handle::cusparseHandle_t, m::Cint, n::Cint,
                                          descrA::cusparseMatDescr_t,
                                          cscSortedValA::CuPtr{cuDoubleComplex},
                                          cscSortedRowIndA::CuPtr{Cint},
                                          cscSortedColPtrA::CuPtr{Cint},
                                          A::CuPtr{cuDoubleComplex},
                                          lda::Cint)::cusparseStatus_t
end

@checked function cusparseXcoo2csr(handle, cooRowInd, nnz, m, csrSortedRowPtr, idxBase)
    initialize_context()
    @ccall libcusparse.cusparseXcoo2csr(handle::cusparseHandle_t, cooRowInd::CuPtr{Cint},
                                        nnz::Cint, m::Cint, csrSortedRowPtr::CuPtr{Cint},
                                        idxBase::cusparseIndexBase_t)::cusparseStatus_t
end

@checked function cusparseXcsr2coo(handle, csrSortedRowPtr, nnz, m, cooRowInd, idxBase)
    initialize_context()
    @ccall libcusparse.cusparseXcsr2coo(handle::cusparseHandle_t,
                                        csrSortedRowPtr::CuPtr{Cint}, nnz::Cint, m::Cint,
                                        cooRowInd::CuPtr{Cint},
                                        idxBase::cusparseIndexBase_t)::cusparseStatus_t
end

@checked function cusparseXcsr2bsrNnz(handle, dirA, m, n, descrA, csrSortedRowPtrA,
                                      csrSortedColIndA, blockDim, descrC, bsrSortedRowPtrC,
                                      nnzTotalDevHostPtr)
    initialize_context()
    @ccall libcusparse.cusparseXcsr2bsrNnz(handle::cusparseHandle_t,
                                           dirA::cusparseDirection_t, m::Cint, n::Cint,
                                           descrA::cusparseMatDescr_t,
                                           csrSortedRowPtrA::CuPtr{Cint},
                                           csrSortedColIndA::CuPtr{Cint}, blockDim::Cint,
                                           descrC::cusparseMatDescr_t,
                                           bsrSortedRowPtrC::CuPtr{Cint},
                                           nnzTotalDevHostPtr::PtrOrCuPtr{Cint})::cusparseStatus_t
end

@checked function cusparseScsr2bsr(handle, dirA, m, n, descrA, csrSortedValA,
                                   csrSortedRowPtrA, csrSortedColIndA, blockDim, descrC,
                                   bsrSortedValC, bsrSortedRowPtrC, bsrSortedColIndC)
    initialize_context()
    @ccall libcusparse.cusparseScsr2bsr(handle::cusparseHandle_t, dirA::cusparseDirection_t,
                                        m::Cint, n::Cint, descrA::cusparseMatDescr_t,
                                        csrSortedValA::CuPtr{Cfloat},
                                        csrSortedRowPtrA::CuPtr{Cint},
                                        csrSortedColIndA::CuPtr{Cint}, blockDim::Cint,
                                        descrC::cusparseMatDescr_t,
                                        bsrSortedValC::CuPtr{Cfloat},
                                        bsrSortedRowPtrC::CuPtr{Cint},
                                        bsrSortedColIndC::CuPtr{Cint})::cusparseStatus_t
end

@checked function cusparseDcsr2bsr(handle, dirA, m, n, descrA, csrSortedValA,
                                   csrSortedRowPtrA, csrSortedColIndA, blockDim, descrC,
                                   bsrSortedValC, bsrSortedRowPtrC, bsrSortedColIndC)
    initialize_context()
    @ccall libcusparse.cusparseDcsr2bsr(handle::cusparseHandle_t, dirA::cusparseDirection_t,
                                        m::Cint, n::Cint, descrA::cusparseMatDescr_t,
                                        csrSortedValA::CuPtr{Cdouble},
                                        csrSortedRowPtrA::CuPtr{Cint},
                                        csrSortedColIndA::CuPtr{Cint}, blockDim::Cint,
                                        descrC::cusparseMatDescr_t,
                                        bsrSortedValC::CuPtr{Cdouble},
                                        bsrSortedRowPtrC::CuPtr{Cint},
                                        bsrSortedColIndC::CuPtr{Cint})::cusparseStatus_t
end

@checked function cusparseCcsr2bsr(handle, dirA, m, n, descrA, csrSortedValA,
                                   csrSortedRowPtrA, csrSortedColIndA, blockDim, descrC,
                                   bsrSortedValC, bsrSortedRowPtrC, bsrSortedColIndC)
    initialize_context()
    @ccall libcusparse.cusparseCcsr2bsr(handle::cusparseHandle_t, dirA::cusparseDirection_t,
                                        m::Cint, n::Cint, descrA::cusparseMatDescr_t,
                                        csrSortedValA::CuPtr{cuComplex},
                                        csrSortedRowPtrA::CuPtr{Cint},
                                        csrSortedColIndA::CuPtr{Cint}, blockDim::Cint,
                                        descrC::cusparseMatDescr_t,
                                        bsrSortedValC::CuPtr{cuComplex},
                                        bsrSortedRowPtrC::CuPtr{Cint},
                                        bsrSortedColIndC::CuPtr{Cint})::cusparseStatus_t
end

@checked function cusparseZcsr2bsr(handle, dirA, m, n, descrA, csrSortedValA,
                                   csrSortedRowPtrA, csrSortedColIndA, blockDim, descrC,
                                   bsrSortedValC, bsrSortedRowPtrC, bsrSortedColIndC)
    initialize_context()
    @ccall libcusparse.cusparseZcsr2bsr(handle::cusparseHandle_t, dirA::cusparseDirection_t,
                                        m::Cint, n::Cint, descrA::cusparseMatDescr_t,
                                        csrSortedValA::CuPtr{cuDoubleComplex},
                                        csrSortedRowPtrA::CuPtr{Cint},
                                        csrSortedColIndA::CuPtr{Cint}, blockDim::Cint,
                                        descrC::cusparseMatDescr_t,
                                        bsrSortedValC::CuPtr{cuDoubleComplex},
                                        bsrSortedRowPtrC::CuPtr{Cint},
                                        bsrSortedColIndC::CuPtr{Cint})::cusparseStatus_t
end

@checked function cusparseSbsr2csr(handle, dirA, mb, nb, descrA, bsrSortedValA,
                                   bsrSortedRowPtrA, bsrSortedColIndA, blockDim, descrC,
                                   csrSortedValC, csrSortedRowPtrC, csrSortedColIndC)
    initialize_context()
    @ccall libcusparse.cusparseSbsr2csr(handle::cusparseHandle_t, dirA::cusparseDirection_t,
                                        mb::Cint, nb::Cint, descrA::cusparseMatDescr_t,
                                        bsrSortedValA::CuPtr{Cfloat},
                                        bsrSortedRowPtrA::CuPtr{Cint},
                                        bsrSortedColIndA::CuPtr{Cint}, blockDim::Cint,
                                        descrC::cusparseMatDescr_t,
                                        csrSortedValC::CuPtr{Cfloat},
                                        csrSortedRowPtrC::CuPtr{Cint},
                                        csrSortedColIndC::CuPtr{Cint})::cusparseStatus_t
end

@checked function cusparseDbsr2csr(handle, dirA, mb, nb, descrA, bsrSortedValA,
                                   bsrSortedRowPtrA, bsrSortedColIndA, blockDim, descrC,
                                   csrSortedValC, csrSortedRowPtrC, csrSortedColIndC)
    initialize_context()
    @ccall libcusparse.cusparseDbsr2csr(handle::cusparseHandle_t, dirA::cusparseDirection_t,
                                        mb::Cint, nb::Cint, descrA::cusparseMatDescr_t,
                                        bsrSortedValA::CuPtr{Cdouble},
                                        bsrSortedRowPtrA::CuPtr{Cint},
                                        bsrSortedColIndA::CuPtr{Cint}, blockDim::Cint,
                                        descrC::cusparseMatDescr_t,
                                        csrSortedValC::CuPtr{Cdouble},
                                        csrSortedRowPtrC::CuPtr{Cint},
                                        csrSortedColIndC::CuPtr{Cint})::cusparseStatus_t
end

@checked function cusparseCbsr2csr(handle, dirA, mb, nb, descrA, bsrSortedValA,
                                   bsrSortedRowPtrA, bsrSortedColIndA, blockDim, descrC,
                                   csrSortedValC, csrSortedRowPtrC, csrSortedColIndC)
    initialize_context()
    @ccall libcusparse.cusparseCbsr2csr(handle::cusparseHandle_t, dirA::cusparseDirection_t,
                                        mb::Cint, nb::Cint, descrA::cusparseMatDescr_t,
                                        bsrSortedValA::CuPtr{cuComplex},
                                        bsrSortedRowPtrA::CuPtr{Cint},
                                        bsrSortedColIndA::CuPtr{Cint}, blockDim::Cint,
                                        descrC::cusparseMatDescr_t,
                                        csrSortedValC::CuPtr{cuComplex},
                                        csrSortedRowPtrC::CuPtr{Cint},
                                        csrSortedColIndC::CuPtr{Cint})::cusparseStatus_t
end

@checked function cusparseZbsr2csr(handle, dirA, mb, nb, descrA, bsrSortedValA,
                                   bsrSortedRowPtrA, bsrSortedColIndA, blockDim, descrC,
                                   csrSortedValC, csrSortedRowPtrC, csrSortedColIndC)
    initialize_context()
    @ccall libcusparse.cusparseZbsr2csr(handle::cusparseHandle_t, dirA::cusparseDirection_t,
                                        mb::Cint, nb::Cint, descrA::cusparseMatDescr_t,
                                        bsrSortedValA::CuPtr{cuDoubleComplex},
                                        bsrSortedRowPtrA::CuPtr{Cint},
                                        bsrSortedColIndA::CuPtr{Cint}, blockDim::Cint,
                                        descrC::cusparseMatDescr_t,
                                        csrSortedValC::CuPtr{cuDoubleComplex},
                                        csrSortedRowPtrC::CuPtr{Cint},
                                        csrSortedColIndC::CuPtr{Cint})::cusparseStatus_t
end

@checked function cusparseSgebsr2gebsc_bufferSize(handle, mb, nb, nnzb, bsrSortedVal,
                                                  bsrSortedRowPtr, bsrSortedColInd,
                                                  rowBlockDim, colBlockDim,
                                                  pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseSgebsr2gebsc_bufferSize(handle::cusparseHandle_t, mb::Cint,
                                                       nb::Cint, nnzb::Cint,
                                                       bsrSortedVal::CuPtr{Cfloat},
                                                       bsrSortedRowPtr::CuPtr{Cint},
                                                       bsrSortedColInd::CuPtr{Cint},
                                                       rowBlockDim::Cint, colBlockDim::Cint,
                                                       pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseDgebsr2gebsc_bufferSize(handle, mb, nb, nnzb, bsrSortedVal,
                                                  bsrSortedRowPtr, bsrSortedColInd,
                                                  rowBlockDim, colBlockDim,
                                                  pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseDgebsr2gebsc_bufferSize(handle::cusparseHandle_t, mb::Cint,
                                                       nb::Cint, nnzb::Cint,
                                                       bsrSortedVal::CuPtr{Cdouble},
                                                       bsrSortedRowPtr::CuPtr{Cint},
                                                       bsrSortedColInd::CuPtr{Cint},
                                                       rowBlockDim::Cint, colBlockDim::Cint,
                                                       pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseCgebsr2gebsc_bufferSize(handle, mb, nb, nnzb, bsrSortedVal,
                                                  bsrSortedRowPtr, bsrSortedColInd,
                                                  rowBlockDim, colBlockDim,
                                                  pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseCgebsr2gebsc_bufferSize(handle::cusparseHandle_t, mb::Cint,
                                                       nb::Cint, nnzb::Cint,
                                                       bsrSortedVal::CuPtr{cuComplex},
                                                       bsrSortedRowPtr::CuPtr{Cint},
                                                       bsrSortedColInd::CuPtr{Cint},
                                                       rowBlockDim::Cint, colBlockDim::Cint,
                                                       pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseZgebsr2gebsc_bufferSize(handle, mb, nb, nnzb, bsrSortedVal,
                                                  bsrSortedRowPtr, bsrSortedColInd,
                                                  rowBlockDim, colBlockDim,
                                                  pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseZgebsr2gebsc_bufferSize(handle::cusparseHandle_t, mb::Cint,
                                                       nb::Cint, nnzb::Cint,
                                                       bsrSortedVal::CuPtr{cuDoubleComplex},
                                                       bsrSortedRowPtr::CuPtr{Cint},
                                                       bsrSortedColInd::CuPtr{Cint},
                                                       rowBlockDim::Cint, colBlockDim::Cint,
                                                       pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseSgebsr2gebsc_bufferSizeExt(handle, mb, nb, nnzb, bsrSortedVal,
                                                     bsrSortedRowPtr, bsrSortedColInd,
                                                     rowBlockDim, colBlockDim, pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseSgebsr2gebsc_bufferSizeExt(handle::cusparseHandle_t,
                                                          mb::Cint, nb::Cint, nnzb::Cint,
                                                          bsrSortedVal::CuPtr{Cfloat},
                                                          bsrSortedRowPtr::CuPtr{Cint},
                                                          bsrSortedColInd::CuPtr{Cint},
                                                          rowBlockDim::Cint,
                                                          colBlockDim::Cint,
                                                          pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseDgebsr2gebsc_bufferSizeExt(handle, mb, nb, nnzb, bsrSortedVal,
                                                     bsrSortedRowPtr, bsrSortedColInd,
                                                     rowBlockDim, colBlockDim, pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseDgebsr2gebsc_bufferSizeExt(handle::cusparseHandle_t,
                                                          mb::Cint, nb::Cint, nnzb::Cint,
                                                          bsrSortedVal::CuPtr{Cdouble},
                                                          bsrSortedRowPtr::CuPtr{Cint},
                                                          bsrSortedColInd::CuPtr{Cint},
                                                          rowBlockDim::Cint,
                                                          colBlockDim::Cint,
                                                          pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseCgebsr2gebsc_bufferSizeExt(handle, mb, nb, nnzb, bsrSortedVal,
                                                     bsrSortedRowPtr, bsrSortedColInd,
                                                     rowBlockDim, colBlockDim, pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseCgebsr2gebsc_bufferSizeExt(handle::cusparseHandle_t,
                                                          mb::Cint, nb::Cint, nnzb::Cint,
                                                          bsrSortedVal::CuPtr{cuComplex},
                                                          bsrSortedRowPtr::CuPtr{Cint},
                                                          bsrSortedColInd::CuPtr{Cint},
                                                          rowBlockDim::Cint,
                                                          colBlockDim::Cint,
                                                          pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseZgebsr2gebsc_bufferSizeExt(handle, mb, nb, nnzb, bsrSortedVal,
                                                     bsrSortedRowPtr, bsrSortedColInd,
                                                     rowBlockDim, colBlockDim, pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseZgebsr2gebsc_bufferSizeExt(handle::cusparseHandle_t,
                                                          mb::Cint, nb::Cint, nnzb::Cint,
                                                          bsrSortedVal::CuPtr{cuDoubleComplex},
                                                          bsrSortedRowPtr::CuPtr{Cint},
                                                          bsrSortedColInd::CuPtr{Cint},
                                                          rowBlockDim::Cint,
                                                          colBlockDim::Cint,
                                                          pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseSgebsr2gebsc(handle, mb, nb, nnzb, bsrSortedVal, bsrSortedRowPtr,
                                       bsrSortedColInd, rowBlockDim, colBlockDim, bscVal,
                                       bscRowInd, bscColPtr, copyValues, idxBase, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSgebsr2gebsc(handle::cusparseHandle_t, mb::Cint, nb::Cint,
                                            nnzb::Cint, bsrSortedVal::CuPtr{Cfloat},
                                            bsrSortedRowPtr::CuPtr{Cint},
                                            bsrSortedColInd::CuPtr{Cint}, rowBlockDim::Cint,
                                            colBlockDim::Cint, bscVal::CuPtr{Cfloat},
                                            bscRowInd::CuPtr{Cint}, bscColPtr::CuPtr{Cint},
                                            copyValues::cusparseAction_t,
                                            idxBase::cusparseIndexBase_t,
                                            pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDgebsr2gebsc(handle, mb, nb, nnzb, bsrSortedVal, bsrSortedRowPtr,
                                       bsrSortedColInd, rowBlockDim, colBlockDim, bscVal,
                                       bscRowInd, bscColPtr, copyValues, idxBase, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDgebsr2gebsc(handle::cusparseHandle_t, mb::Cint, nb::Cint,
                                            nnzb::Cint, bsrSortedVal::CuPtr{Cdouble},
                                            bsrSortedRowPtr::CuPtr{Cint},
                                            bsrSortedColInd::CuPtr{Cint}, rowBlockDim::Cint,
                                            colBlockDim::Cint, bscVal::CuPtr{Cdouble},
                                            bscRowInd::CuPtr{Cint}, bscColPtr::CuPtr{Cint},
                                            copyValues::cusparseAction_t,
                                            idxBase::cusparseIndexBase_t,
                                            pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCgebsr2gebsc(handle, mb, nb, nnzb, bsrSortedVal, bsrSortedRowPtr,
                                       bsrSortedColInd, rowBlockDim, colBlockDim, bscVal,
                                       bscRowInd, bscColPtr, copyValues, idxBase, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCgebsr2gebsc(handle::cusparseHandle_t, mb::Cint, nb::Cint,
                                            nnzb::Cint, bsrSortedVal::CuPtr{cuComplex},
                                            bsrSortedRowPtr::CuPtr{Cint},
                                            bsrSortedColInd::CuPtr{Cint}, rowBlockDim::Cint,
                                            colBlockDim::Cint, bscVal::CuPtr{cuComplex},
                                            bscRowInd::CuPtr{Cint}, bscColPtr::CuPtr{Cint},
                                            copyValues::cusparseAction_t,
                                            idxBase::cusparseIndexBase_t,
                                            pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZgebsr2gebsc(handle, mb, nb, nnzb, bsrSortedVal, bsrSortedRowPtr,
                                       bsrSortedColInd, rowBlockDim, colBlockDim, bscVal,
                                       bscRowInd, bscColPtr, copyValues, idxBase, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZgebsr2gebsc(handle::cusparseHandle_t, mb::Cint, nb::Cint,
                                            nnzb::Cint,
                                            bsrSortedVal::CuPtr{cuDoubleComplex},
                                            bsrSortedRowPtr::CuPtr{Cint},
                                            bsrSortedColInd::CuPtr{Cint}, rowBlockDim::Cint,
                                            colBlockDim::Cint,
                                            bscVal::CuPtr{cuDoubleComplex},
                                            bscRowInd::CuPtr{Cint}, bscColPtr::CuPtr{Cint},
                                            copyValues::cusparseAction_t,
                                            idxBase::cusparseIndexBase_t,
                                            pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseXgebsr2csr(handle, dirA, mb, nb, descrA, bsrSortedRowPtrA,
                                     bsrSortedColIndA, rowBlockDim, colBlockDim, descrC,
                                     csrSortedRowPtrC, csrSortedColIndC)
    initialize_context()
    @ccall libcusparse.cusparseXgebsr2csr(handle::cusparseHandle_t,
                                          dirA::cusparseDirection_t, mb::Cint, nb::Cint,
                                          descrA::cusparseMatDescr_t,
                                          bsrSortedRowPtrA::CuPtr{Cint},
                                          bsrSortedColIndA::CuPtr{Cint}, rowBlockDim::Cint,
                                          colBlockDim::Cint, descrC::cusparseMatDescr_t,
                                          csrSortedRowPtrC::CuPtr{Cint},
                                          csrSortedColIndC::CuPtr{Cint})::cusparseStatus_t
end

@checked function cusparseSgebsr2csr(handle, dirA, mb, nb, descrA, bsrSortedValA,
                                     bsrSortedRowPtrA, bsrSortedColIndA, rowBlockDim,
                                     colBlockDim, descrC, csrSortedValC, csrSortedRowPtrC,
                                     csrSortedColIndC)
    initialize_context()
    @ccall libcusparse.cusparseSgebsr2csr(handle::cusparseHandle_t,
                                          dirA::cusparseDirection_t, mb::Cint, nb::Cint,
                                          descrA::cusparseMatDescr_t,
                                          bsrSortedValA::CuPtr{Cfloat},
                                          bsrSortedRowPtrA::CuPtr{Cint},
                                          bsrSortedColIndA::CuPtr{Cint}, rowBlockDim::Cint,
                                          colBlockDim::Cint, descrC::cusparseMatDescr_t,
                                          csrSortedValC::CuPtr{Cfloat},
                                          csrSortedRowPtrC::CuPtr{Cint},
                                          csrSortedColIndC::CuPtr{Cint})::cusparseStatus_t
end

@checked function cusparseDgebsr2csr(handle, dirA, mb, nb, descrA, bsrSortedValA,
                                     bsrSortedRowPtrA, bsrSortedColIndA, rowBlockDim,
                                     colBlockDim, descrC, csrSortedValC, csrSortedRowPtrC,
                                     csrSortedColIndC)
    initialize_context()
    @ccall libcusparse.cusparseDgebsr2csr(handle::cusparseHandle_t,
                                          dirA::cusparseDirection_t, mb::Cint, nb::Cint,
                                          descrA::cusparseMatDescr_t,
                                          bsrSortedValA::CuPtr{Cdouble},
                                          bsrSortedRowPtrA::CuPtr{Cint},
                                          bsrSortedColIndA::CuPtr{Cint}, rowBlockDim::Cint,
                                          colBlockDim::Cint, descrC::cusparseMatDescr_t,
                                          csrSortedValC::CuPtr{Cdouble},
                                          csrSortedRowPtrC::CuPtr{Cint},
                                          csrSortedColIndC::CuPtr{Cint})::cusparseStatus_t
end

@checked function cusparseCgebsr2csr(handle, dirA, mb, nb, descrA, bsrSortedValA,
                                     bsrSortedRowPtrA, bsrSortedColIndA, rowBlockDim,
                                     colBlockDim, descrC, csrSortedValC, csrSortedRowPtrC,
                                     csrSortedColIndC)
    initialize_context()
    @ccall libcusparse.cusparseCgebsr2csr(handle::cusparseHandle_t,
                                          dirA::cusparseDirection_t, mb::Cint, nb::Cint,
                                          descrA::cusparseMatDescr_t,
                                          bsrSortedValA::CuPtr{cuComplex},
                                          bsrSortedRowPtrA::CuPtr{Cint},
                                          bsrSortedColIndA::CuPtr{Cint}, rowBlockDim::Cint,
                                          colBlockDim::Cint, descrC::cusparseMatDescr_t,
                                          csrSortedValC::CuPtr{cuComplex},
                                          csrSortedRowPtrC::CuPtr{Cint},
                                          csrSortedColIndC::CuPtr{Cint})::cusparseStatus_t
end

@checked function cusparseZgebsr2csr(handle, dirA, mb, nb, descrA, bsrSortedValA,
                                     bsrSortedRowPtrA, bsrSortedColIndA, rowBlockDim,
                                     colBlockDim, descrC, csrSortedValC, csrSortedRowPtrC,
                                     csrSortedColIndC)
    initialize_context()
    @ccall libcusparse.cusparseZgebsr2csr(handle::cusparseHandle_t,
                                          dirA::cusparseDirection_t, mb::Cint, nb::Cint,
                                          descrA::cusparseMatDescr_t,
                                          bsrSortedValA::CuPtr{cuDoubleComplex},
                                          bsrSortedRowPtrA::CuPtr{Cint},
                                          bsrSortedColIndA::CuPtr{Cint}, rowBlockDim::Cint,
                                          colBlockDim::Cint, descrC::cusparseMatDescr_t,
                                          csrSortedValC::CuPtr{cuDoubleComplex},
                                          csrSortedRowPtrC::CuPtr{Cint},
                                          csrSortedColIndC::CuPtr{Cint})::cusparseStatus_t
end

@checked function cusparseScsr2gebsr_bufferSize(handle, dirA, m, n, descrA, csrSortedValA,
                                                csrSortedRowPtrA, csrSortedColIndA,
                                                rowBlockDim, colBlockDim,
                                                pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseScsr2gebsr_bufferSize(handle::cusparseHandle_t,
                                                     dirA::cusparseDirection_t, m::Cint,
                                                     n::Cint, descrA::cusparseMatDescr_t,
                                                     csrSortedValA::CuPtr{Cfloat},
                                                     csrSortedRowPtrA::CuPtr{Cint},
                                                     csrSortedColIndA::CuPtr{Cint},
                                                     rowBlockDim::Cint, colBlockDim::Cint,
                                                     pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseDcsr2gebsr_bufferSize(handle, dirA, m, n, descrA, csrSortedValA,
                                                csrSortedRowPtrA, csrSortedColIndA,
                                                rowBlockDim, colBlockDim,
                                                pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseDcsr2gebsr_bufferSize(handle::cusparseHandle_t,
                                                     dirA::cusparseDirection_t, m::Cint,
                                                     n::Cint, descrA::cusparseMatDescr_t,
                                                     csrSortedValA::CuPtr{Cdouble},
                                                     csrSortedRowPtrA::CuPtr{Cint},
                                                     csrSortedColIndA::CuPtr{Cint},
                                                     rowBlockDim::Cint, colBlockDim::Cint,
                                                     pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseCcsr2gebsr_bufferSize(handle, dirA, m, n, descrA, csrSortedValA,
                                                csrSortedRowPtrA, csrSortedColIndA,
                                                rowBlockDim, colBlockDim,
                                                pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseCcsr2gebsr_bufferSize(handle::cusparseHandle_t,
                                                     dirA::cusparseDirection_t, m::Cint,
                                                     n::Cint, descrA::cusparseMatDescr_t,
                                                     csrSortedValA::CuPtr{cuComplex},
                                                     csrSortedRowPtrA::CuPtr{Cint},
                                                     csrSortedColIndA::CuPtr{Cint},
                                                     rowBlockDim::Cint, colBlockDim::Cint,
                                                     pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseZcsr2gebsr_bufferSize(handle, dirA, m, n, descrA, csrSortedValA,
                                                csrSortedRowPtrA, csrSortedColIndA,
                                                rowBlockDim, colBlockDim,
                                                pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseZcsr2gebsr_bufferSize(handle::cusparseHandle_t,
                                                     dirA::cusparseDirection_t, m::Cint,
                                                     n::Cint, descrA::cusparseMatDescr_t,
                                                     csrSortedValA::CuPtr{cuDoubleComplex},
                                                     csrSortedRowPtrA::CuPtr{Cint},
                                                     csrSortedColIndA::CuPtr{Cint},
                                                     rowBlockDim::Cint, colBlockDim::Cint,
                                                     pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseScsr2gebsr_bufferSizeExt(handle, dirA, m, n, descrA,
                                                   csrSortedValA, csrSortedRowPtrA,
                                                   csrSortedColIndA, rowBlockDim,
                                                   colBlockDim, pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseScsr2gebsr_bufferSizeExt(handle::cusparseHandle_t,
                                                        dirA::cusparseDirection_t, m::Cint,
                                                        n::Cint, descrA::cusparseMatDescr_t,
                                                        csrSortedValA::CuPtr{Cfloat},
                                                        csrSortedRowPtrA::CuPtr{Cint},
                                                        csrSortedColIndA::CuPtr{Cint},
                                                        rowBlockDim::Cint,
                                                        colBlockDim::Cint,
                                                        pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseDcsr2gebsr_bufferSizeExt(handle, dirA, m, n, descrA,
                                                   csrSortedValA, csrSortedRowPtrA,
                                                   csrSortedColIndA, rowBlockDim,
                                                   colBlockDim, pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseDcsr2gebsr_bufferSizeExt(handle::cusparseHandle_t,
                                                        dirA::cusparseDirection_t, m::Cint,
                                                        n::Cint, descrA::cusparseMatDescr_t,
                                                        csrSortedValA::CuPtr{Cdouble},
                                                        csrSortedRowPtrA::CuPtr{Cint},
                                                        csrSortedColIndA::CuPtr{Cint},
                                                        rowBlockDim::Cint,
                                                        colBlockDim::Cint,
                                                        pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseCcsr2gebsr_bufferSizeExt(handle, dirA, m, n, descrA,
                                                   csrSortedValA, csrSortedRowPtrA,
                                                   csrSortedColIndA, rowBlockDim,
                                                   colBlockDim, pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseCcsr2gebsr_bufferSizeExt(handle::cusparseHandle_t,
                                                        dirA::cusparseDirection_t, m::Cint,
                                                        n::Cint, descrA::cusparseMatDescr_t,
                                                        csrSortedValA::CuPtr{cuComplex},
                                                        csrSortedRowPtrA::CuPtr{Cint},
                                                        csrSortedColIndA::CuPtr{Cint},
                                                        rowBlockDim::Cint,
                                                        colBlockDim::Cint,
                                                        pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseZcsr2gebsr_bufferSizeExt(handle, dirA, m, n, descrA,
                                                   csrSortedValA, csrSortedRowPtrA,
                                                   csrSortedColIndA, rowBlockDim,
                                                   colBlockDim, pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseZcsr2gebsr_bufferSizeExt(handle::cusparseHandle_t,
                                                        dirA::cusparseDirection_t, m::Cint,
                                                        n::Cint, descrA::cusparseMatDescr_t,
                                                        csrSortedValA::CuPtr{cuDoubleComplex},
                                                        csrSortedRowPtrA::CuPtr{Cint},
                                                        csrSortedColIndA::CuPtr{Cint},
                                                        rowBlockDim::Cint,
                                                        colBlockDim::Cint,
                                                        pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseXcsr2gebsrNnz(handle, dirA, m, n, descrA, csrSortedRowPtrA,
                                        csrSortedColIndA, descrC, bsrSortedRowPtrC,
                                        rowBlockDim, colBlockDim, nnzTotalDevHostPtr,
                                        pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseXcsr2gebsrNnz(handle::cusparseHandle_t,
                                             dirA::cusparseDirection_t, m::Cint, n::Cint,
                                             descrA::cusparseMatDescr_t,
                                             csrSortedRowPtrA::CuPtr{Cint},
                                             csrSortedColIndA::CuPtr{Cint},
                                             descrC::cusparseMatDescr_t,
                                             bsrSortedRowPtrC::CuPtr{Cint},
                                             rowBlockDim::Cint, colBlockDim::Cint,
                                             nnzTotalDevHostPtr::PtrOrCuPtr{Cint},
                                             pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseScsr2gebsr(handle, dirA, m, n, descrA, csrSortedValA,
                                     csrSortedRowPtrA, csrSortedColIndA, descrC,
                                     bsrSortedValC, bsrSortedRowPtrC, bsrSortedColIndC,
                                     rowBlockDim, colBlockDim, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseScsr2gebsr(handle::cusparseHandle_t,
                                          dirA::cusparseDirection_t, m::Cint, n::Cint,
                                          descrA::cusparseMatDescr_t,
                                          csrSortedValA::CuPtr{Cfloat},
                                          csrSortedRowPtrA::CuPtr{Cint},
                                          csrSortedColIndA::CuPtr{Cint},
                                          descrC::cusparseMatDescr_t,
                                          bsrSortedValC::CuPtr{Cfloat},
                                          bsrSortedRowPtrC::CuPtr{Cint},
                                          bsrSortedColIndC::CuPtr{Cint}, rowBlockDim::Cint,
                                          colBlockDim::Cint,
                                          pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDcsr2gebsr(handle, dirA, m, n, descrA, csrSortedValA,
                                     csrSortedRowPtrA, csrSortedColIndA, descrC,
                                     bsrSortedValC, bsrSortedRowPtrC, bsrSortedColIndC,
                                     rowBlockDim, colBlockDim, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDcsr2gebsr(handle::cusparseHandle_t,
                                          dirA::cusparseDirection_t, m::Cint, n::Cint,
                                          descrA::cusparseMatDescr_t,
                                          csrSortedValA::CuPtr{Cdouble},
                                          csrSortedRowPtrA::CuPtr{Cint},
                                          csrSortedColIndA::CuPtr{Cint},
                                          descrC::cusparseMatDescr_t,
                                          bsrSortedValC::CuPtr{Cdouble},
                                          bsrSortedRowPtrC::CuPtr{Cint},
                                          bsrSortedColIndC::CuPtr{Cint}, rowBlockDim::Cint,
                                          colBlockDim::Cint,
                                          pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCcsr2gebsr(handle, dirA, m, n, descrA, csrSortedValA,
                                     csrSortedRowPtrA, csrSortedColIndA, descrC,
                                     bsrSortedValC, bsrSortedRowPtrC, bsrSortedColIndC,
                                     rowBlockDim, colBlockDim, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCcsr2gebsr(handle::cusparseHandle_t,
                                          dirA::cusparseDirection_t, m::Cint, n::Cint,
                                          descrA::cusparseMatDescr_t,
                                          csrSortedValA::CuPtr{cuComplex},
                                          csrSortedRowPtrA::CuPtr{Cint},
                                          csrSortedColIndA::CuPtr{Cint},
                                          descrC::cusparseMatDescr_t,
                                          bsrSortedValC::CuPtr{cuComplex},
                                          bsrSortedRowPtrC::CuPtr{Cint},
                                          bsrSortedColIndC::CuPtr{Cint}, rowBlockDim::Cint,
                                          colBlockDim::Cint,
                                          pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZcsr2gebsr(handle, dirA, m, n, descrA, csrSortedValA,
                                     csrSortedRowPtrA, csrSortedColIndA, descrC,
                                     bsrSortedValC, bsrSortedRowPtrC, bsrSortedColIndC,
                                     rowBlockDim, colBlockDim, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZcsr2gebsr(handle::cusparseHandle_t,
                                          dirA::cusparseDirection_t, m::Cint, n::Cint,
                                          descrA::cusparseMatDescr_t,
                                          csrSortedValA::CuPtr{cuDoubleComplex},
                                          csrSortedRowPtrA::CuPtr{Cint},
                                          csrSortedColIndA::CuPtr{Cint},
                                          descrC::cusparseMatDescr_t,
                                          bsrSortedValC::CuPtr{cuDoubleComplex},
                                          bsrSortedRowPtrC::CuPtr{Cint},
                                          bsrSortedColIndC::CuPtr{Cint}, rowBlockDim::Cint,
                                          colBlockDim::Cint,
                                          pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSgebsr2gebsr_bufferSize(handle, dirA, mb, nb, nnzb, descrA,
                                                  bsrSortedValA, bsrSortedRowPtrA,
                                                  bsrSortedColIndA, rowBlockDimA,
                                                  colBlockDimA, rowBlockDimC, colBlockDimC,
                                                  pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseSgebsr2gebsr_bufferSize(handle::cusparseHandle_t,
                                                       dirA::cusparseDirection_t, mb::Cint,
                                                       nb::Cint, nnzb::Cint,
                                                       descrA::cusparseMatDescr_t,
                                                       bsrSortedValA::CuPtr{Cfloat},
                                                       bsrSortedRowPtrA::CuPtr{Cint},
                                                       bsrSortedColIndA::CuPtr{Cint},
                                                       rowBlockDimA::Cint,
                                                       colBlockDimA::Cint,
                                                       rowBlockDimC::Cint,
                                                       colBlockDimC::Cint,
                                                       pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseDgebsr2gebsr_bufferSize(handle, dirA, mb, nb, nnzb, descrA,
                                                  bsrSortedValA, bsrSortedRowPtrA,
                                                  bsrSortedColIndA, rowBlockDimA,
                                                  colBlockDimA, rowBlockDimC, colBlockDimC,
                                                  pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseDgebsr2gebsr_bufferSize(handle::cusparseHandle_t,
                                                       dirA::cusparseDirection_t, mb::Cint,
                                                       nb::Cint, nnzb::Cint,
                                                       descrA::cusparseMatDescr_t,
                                                       bsrSortedValA::CuPtr{Cdouble},
                                                       bsrSortedRowPtrA::CuPtr{Cint},
                                                       bsrSortedColIndA::CuPtr{Cint},
                                                       rowBlockDimA::Cint,
                                                       colBlockDimA::Cint,
                                                       rowBlockDimC::Cint,
                                                       colBlockDimC::Cint,
                                                       pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseCgebsr2gebsr_bufferSize(handle, dirA, mb, nb, nnzb, descrA,
                                                  bsrSortedValA, bsrSortedRowPtrA,
                                                  bsrSortedColIndA, rowBlockDimA,
                                                  colBlockDimA, rowBlockDimC, colBlockDimC,
                                                  pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseCgebsr2gebsr_bufferSize(handle::cusparseHandle_t,
                                                       dirA::cusparseDirection_t, mb::Cint,
                                                       nb::Cint, nnzb::Cint,
                                                       descrA::cusparseMatDescr_t,
                                                       bsrSortedValA::CuPtr{cuComplex},
                                                       bsrSortedRowPtrA::CuPtr{Cint},
                                                       bsrSortedColIndA::CuPtr{Cint},
                                                       rowBlockDimA::Cint,
                                                       colBlockDimA::Cint,
                                                       rowBlockDimC::Cint,
                                                       colBlockDimC::Cint,
                                                       pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseZgebsr2gebsr_bufferSize(handle, dirA, mb, nb, nnzb, descrA,
                                                  bsrSortedValA, bsrSortedRowPtrA,
                                                  bsrSortedColIndA, rowBlockDimA,
                                                  colBlockDimA, rowBlockDimC, colBlockDimC,
                                                  pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseZgebsr2gebsr_bufferSize(handle::cusparseHandle_t,
                                                       dirA::cusparseDirection_t, mb::Cint,
                                                       nb::Cint, nnzb::Cint,
                                                       descrA::cusparseMatDescr_t,
                                                       bsrSortedValA::CuPtr{cuDoubleComplex},
                                                       bsrSortedRowPtrA::CuPtr{Cint},
                                                       bsrSortedColIndA::CuPtr{Cint},
                                                       rowBlockDimA::Cint,
                                                       colBlockDimA::Cint,
                                                       rowBlockDimC::Cint,
                                                       colBlockDimC::Cint,
                                                       pBufferSizeInBytes::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseSgebsr2gebsr_bufferSizeExt(handle, dirA, mb, nb, nnzb, descrA,
                                                     bsrSortedValA, bsrSortedRowPtrA,
                                                     bsrSortedColIndA, rowBlockDimA,
                                                     colBlockDimA, rowBlockDimC,
                                                     colBlockDimC, pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseSgebsr2gebsr_bufferSizeExt(handle::cusparseHandle_t,
                                                          dirA::cusparseDirection_t,
                                                          mb::Cint, nb::Cint, nnzb::Cint,
                                                          descrA::cusparseMatDescr_t,
                                                          bsrSortedValA::CuPtr{Cfloat},
                                                          bsrSortedRowPtrA::CuPtr{Cint},
                                                          bsrSortedColIndA::CuPtr{Cint},
                                                          rowBlockDimA::Cint,
                                                          colBlockDimA::Cint,
                                                          rowBlockDimC::Cint,
                                                          colBlockDimC::Cint,
                                                          pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseDgebsr2gebsr_bufferSizeExt(handle, dirA, mb, nb, nnzb, descrA,
                                                     bsrSortedValA, bsrSortedRowPtrA,
                                                     bsrSortedColIndA, rowBlockDimA,
                                                     colBlockDimA, rowBlockDimC,
                                                     colBlockDimC, pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseDgebsr2gebsr_bufferSizeExt(handle::cusparseHandle_t,
                                                          dirA::cusparseDirection_t,
                                                          mb::Cint, nb::Cint, nnzb::Cint,
                                                          descrA::cusparseMatDescr_t,
                                                          bsrSortedValA::CuPtr{Cdouble},
                                                          bsrSortedRowPtrA::CuPtr{Cint},
                                                          bsrSortedColIndA::CuPtr{Cint},
                                                          rowBlockDimA::Cint,
                                                          colBlockDimA::Cint,
                                                          rowBlockDimC::Cint,
                                                          colBlockDimC::Cint,
                                                          pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseCgebsr2gebsr_bufferSizeExt(handle, dirA, mb, nb, nnzb, descrA,
                                                     bsrSortedValA, bsrSortedRowPtrA,
                                                     bsrSortedColIndA, rowBlockDimA,
                                                     colBlockDimA, rowBlockDimC,
                                                     colBlockDimC, pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseCgebsr2gebsr_bufferSizeExt(handle::cusparseHandle_t,
                                                          dirA::cusparseDirection_t,
                                                          mb::Cint, nb::Cint, nnzb::Cint,
                                                          descrA::cusparseMatDescr_t,
                                                          bsrSortedValA::CuPtr{cuComplex},
                                                          bsrSortedRowPtrA::CuPtr{Cint},
                                                          bsrSortedColIndA::CuPtr{Cint},
                                                          rowBlockDimA::Cint,
                                                          colBlockDimA::Cint,
                                                          rowBlockDimC::Cint,
                                                          colBlockDimC::Cint,
                                                          pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseZgebsr2gebsr_bufferSizeExt(handle, dirA, mb, nb, nnzb, descrA,
                                                     bsrSortedValA, bsrSortedRowPtrA,
                                                     bsrSortedColIndA, rowBlockDimA,
                                                     colBlockDimA, rowBlockDimC,
                                                     colBlockDimC, pBufferSize)
    initialize_context()
    @ccall libcusparse.cusparseZgebsr2gebsr_bufferSizeExt(handle::cusparseHandle_t,
                                                          dirA::cusparseDirection_t,
                                                          mb::Cint, nb::Cint, nnzb::Cint,
                                                          descrA::cusparseMatDescr_t,
                                                          bsrSortedValA::CuPtr{cuDoubleComplex},
                                                          bsrSortedRowPtrA::CuPtr{Cint},
                                                          bsrSortedColIndA::CuPtr{Cint},
                                                          rowBlockDimA::Cint,
                                                          colBlockDimA::Cint,
                                                          rowBlockDimC::Cint,
                                                          colBlockDimC::Cint,
                                                          pBufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseXgebsr2gebsrNnz(handle, dirA, mb, nb, nnzb, descrA,
                                          bsrSortedRowPtrA, bsrSortedColIndA, rowBlockDimA,
                                          colBlockDimA, descrC, bsrSortedRowPtrC,
                                          rowBlockDimC, colBlockDimC, nnzTotalDevHostPtr,
                                          pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseXgebsr2gebsrNnz(handle::cusparseHandle_t,
                                               dirA::cusparseDirection_t, mb::Cint,
                                               nb::Cint, nnzb::Cint,
                                               descrA::cusparseMatDescr_t,
                                               bsrSortedRowPtrA::CuPtr{Cint},
                                               bsrSortedColIndA::CuPtr{Cint},
                                               rowBlockDimA::Cint, colBlockDimA::Cint,
                                               descrC::cusparseMatDescr_t,
                                               bsrSortedRowPtrC::CuPtr{Cint},
                                               rowBlockDimC::Cint, colBlockDimC::Cint,
                                               nnzTotalDevHostPtr::PtrOrCuPtr{Cint},
                                               pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSgebsr2gebsr(handle, dirA, mb, nb, nnzb, descrA, bsrSortedValA,
                                       bsrSortedRowPtrA, bsrSortedColIndA, rowBlockDimA,
                                       colBlockDimA, descrC, bsrSortedValC,
                                       bsrSortedRowPtrC, bsrSortedColIndC, rowBlockDimC,
                                       colBlockDimC, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSgebsr2gebsr(handle::cusparseHandle_t,
                                            dirA::cusparseDirection_t, mb::Cint, nb::Cint,
                                            nnzb::Cint, descrA::cusparseMatDescr_t,
                                            bsrSortedValA::CuPtr{Cfloat},
                                            bsrSortedRowPtrA::CuPtr{Cint},
                                            bsrSortedColIndA::CuPtr{Cint},
                                            rowBlockDimA::Cint, colBlockDimA::Cint,
                                            descrC::cusparseMatDescr_t,
                                            bsrSortedValC::CuPtr{Cfloat},
                                            bsrSortedRowPtrC::CuPtr{Cint},
                                            bsrSortedColIndC::CuPtr{Cint},
                                            rowBlockDimC::Cint, colBlockDimC::Cint,
                                            pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDgebsr2gebsr(handle, dirA, mb, nb, nnzb, descrA, bsrSortedValA,
                                       bsrSortedRowPtrA, bsrSortedColIndA, rowBlockDimA,
                                       colBlockDimA, descrC, bsrSortedValC,
                                       bsrSortedRowPtrC, bsrSortedColIndC, rowBlockDimC,
                                       colBlockDimC, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDgebsr2gebsr(handle::cusparseHandle_t,
                                            dirA::cusparseDirection_t, mb::Cint, nb::Cint,
                                            nnzb::Cint, descrA::cusparseMatDescr_t,
                                            bsrSortedValA::CuPtr{Cdouble},
                                            bsrSortedRowPtrA::CuPtr{Cint},
                                            bsrSortedColIndA::CuPtr{Cint},
                                            rowBlockDimA::Cint, colBlockDimA::Cint,
                                            descrC::cusparseMatDescr_t,
                                            bsrSortedValC::CuPtr{Cdouble},
                                            bsrSortedRowPtrC::CuPtr{Cint},
                                            bsrSortedColIndC::CuPtr{Cint},
                                            rowBlockDimC::Cint, colBlockDimC::Cint,
                                            pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCgebsr2gebsr(handle, dirA, mb, nb, nnzb, descrA, bsrSortedValA,
                                       bsrSortedRowPtrA, bsrSortedColIndA, rowBlockDimA,
                                       colBlockDimA, descrC, bsrSortedValC,
                                       bsrSortedRowPtrC, bsrSortedColIndC, rowBlockDimC,
                                       colBlockDimC, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCgebsr2gebsr(handle::cusparseHandle_t,
                                            dirA::cusparseDirection_t, mb::Cint, nb::Cint,
                                            nnzb::Cint, descrA::cusparseMatDescr_t,
                                            bsrSortedValA::CuPtr{cuComplex},
                                            bsrSortedRowPtrA::CuPtr{Cint},
                                            bsrSortedColIndA::CuPtr{Cint},
                                            rowBlockDimA::Cint, colBlockDimA::Cint,
                                            descrC::cusparseMatDescr_t,
                                            bsrSortedValC::CuPtr{cuComplex},
                                            bsrSortedRowPtrC::CuPtr{Cint},
                                            bsrSortedColIndC::CuPtr{Cint},
                                            rowBlockDimC::Cint, colBlockDimC::Cint,
                                            pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZgebsr2gebsr(handle, dirA, mb, nb, nnzb, descrA, bsrSortedValA,
                                       bsrSortedRowPtrA, bsrSortedColIndA, rowBlockDimA,
                                       colBlockDimA, descrC, bsrSortedValC,
                                       bsrSortedRowPtrC, bsrSortedColIndC, rowBlockDimC,
                                       colBlockDimC, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZgebsr2gebsr(handle::cusparseHandle_t,
                                            dirA::cusparseDirection_t, mb::Cint, nb::Cint,
                                            nnzb::Cint, descrA::cusparseMatDescr_t,
                                            bsrSortedValA::CuPtr{cuDoubleComplex},
                                            bsrSortedRowPtrA::CuPtr{Cint},
                                            bsrSortedColIndA::CuPtr{Cint},
                                            rowBlockDimA::Cint, colBlockDimA::Cint,
                                            descrC::cusparseMatDescr_t,
                                            bsrSortedValC::CuPtr{cuDoubleComplex},
                                            bsrSortedRowPtrC::CuPtr{Cint},
                                            bsrSortedColIndC::CuPtr{Cint},
                                            rowBlockDimC::Cint, colBlockDimC::Cint,
                                            pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCreateIdentityPermutation(handle, n, p)
    initialize_context()
    @ccall libcusparse.cusparseCreateIdentityPermutation(handle::cusparseHandle_t, n::Cint,
                                                         p::CuPtr{Cint})::cusparseStatus_t
end

@checked function cusparseXcoosort_bufferSizeExt(handle, m, n, nnz, cooRowsA, cooColsA,
                                                 pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseXcoosort_bufferSizeExt(handle::cusparseHandle_t, m::Cint,
                                                      n::Cint, nnz::Cint,
                                                      cooRowsA::CuPtr{Cint},
                                                      cooColsA::CuPtr{Cint},
                                                      pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseXcoosortByRow(handle, m, n, nnz, cooRowsA, cooColsA, P, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseXcoosortByRow(handle::cusparseHandle_t, m::Cint, n::Cint,
                                             nnz::Cint, cooRowsA::CuPtr{Cint},
                                             cooColsA::CuPtr{Cint}, P::CuPtr{Cint},
                                             pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseXcoosortByColumn(handle, m, n, nnz, cooRowsA, cooColsA, P,
                                           pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseXcoosortByColumn(handle::cusparseHandle_t, m::Cint, n::Cint,
                                                nnz::Cint, cooRowsA::CuPtr{Cint},
                                                cooColsA::CuPtr{Cint}, P::CuPtr{Cint},
                                                pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseXcsrsort_bufferSizeExt(handle, m, n, nnz, csrRowPtrA, csrColIndA,
                                                 pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseXcsrsort_bufferSizeExt(handle::cusparseHandle_t, m::Cint,
                                                      n::Cint, nnz::Cint,
                                                      csrRowPtrA::CuPtr{Cint},
                                                      csrColIndA::CuPtr{Cint},
                                                      pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseXcsrsort(handle, m, n, nnz, descrA, csrRowPtrA, csrColIndA, P,
                                   pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseXcsrsort(handle::cusparseHandle_t, m::Cint, n::Cint,
                                        nnz::Cint, descrA::cusparseMatDescr_t,
                                        csrRowPtrA::CuPtr{Cint}, csrColIndA::CuPtr{Cint},
                                        P::CuPtr{Cint},
                                        pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseXcscsort_bufferSizeExt(handle, m, n, nnz, cscColPtrA, cscRowIndA,
                                                 pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseXcscsort_bufferSizeExt(handle::cusparseHandle_t, m::Cint,
                                                      n::Cint, nnz::Cint,
                                                      cscColPtrA::CuPtr{Cint},
                                                      cscRowIndA::CuPtr{Cint},
                                                      pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseXcscsort(handle, m, n, nnz, descrA, cscColPtrA, cscRowIndA, P,
                                   pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseXcscsort(handle::cusparseHandle_t, m::Cint, n::Cint,
                                        nnz::Cint, descrA::cusparseMatDescr_t,
                                        cscColPtrA::CuPtr{Cint}, cscRowIndA::CuPtr{Cint},
                                        P::CuPtr{Cint},
                                        pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseScsru2csr_bufferSizeExt(handle, m, n, nnz, csrVal, csrRowPtr,
                                                  csrColInd, info, pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseScsru2csr_bufferSizeExt(handle::cusparseHandle_t, m::Cint,
                                                       n::Cint, nnz::Cint,
                                                       csrVal::CuPtr{Cfloat},
                                                       csrRowPtr::CuPtr{Cint},
                                                       csrColInd::CuPtr{Cint},
                                                       info::csru2csrInfo_t,
                                                       pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseDcsru2csr_bufferSizeExt(handle, m, n, nnz, csrVal, csrRowPtr,
                                                  csrColInd, info, pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseDcsru2csr_bufferSizeExt(handle::cusparseHandle_t, m::Cint,
                                                       n::Cint, nnz::Cint,
                                                       csrVal::CuPtr{Cdouble},
                                                       csrRowPtr::CuPtr{Cint},
                                                       csrColInd::CuPtr{Cint},
                                                       info::csru2csrInfo_t,
                                                       pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseCcsru2csr_bufferSizeExt(handle, m, n, nnz, csrVal, csrRowPtr,
                                                  csrColInd, info, pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseCcsru2csr_bufferSizeExt(handle::cusparseHandle_t, m::Cint,
                                                       n::Cint, nnz::Cint,
                                                       csrVal::CuPtr{cuComplex},
                                                       csrRowPtr::CuPtr{Cint},
                                                       csrColInd::CuPtr{Cint},
                                                       info::csru2csrInfo_t,
                                                       pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseZcsru2csr_bufferSizeExt(handle, m, n, nnz, csrVal, csrRowPtr,
                                                  csrColInd, info, pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseZcsru2csr_bufferSizeExt(handle::cusparseHandle_t, m::Cint,
                                                       n::Cint, nnz::Cint,
                                                       csrVal::CuPtr{cuDoubleComplex},
                                                       csrRowPtr::CuPtr{Cint},
                                                       csrColInd::CuPtr{Cint},
                                                       info::csru2csrInfo_t,
                                                       pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseScsru2csr(handle, m, n, nnz, descrA, csrVal, csrRowPtr, csrColInd,
                                    info, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseScsru2csr(handle::cusparseHandle_t, m::Cint, n::Cint,
                                         nnz::Cint, descrA::cusparseMatDescr_t,
                                         csrVal::CuPtr{Cfloat}, csrRowPtr::CuPtr{Cint},
                                         csrColInd::CuPtr{Cint}, info::csru2csrInfo_t,
                                         pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDcsru2csr(handle, m, n, nnz, descrA, csrVal, csrRowPtr, csrColInd,
                                    info, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDcsru2csr(handle::cusparseHandle_t, m::Cint, n::Cint,
                                         nnz::Cint, descrA::cusparseMatDescr_t,
                                         csrVal::CuPtr{Cdouble}, csrRowPtr::CuPtr{Cint},
                                         csrColInd::CuPtr{Cint}, info::csru2csrInfo_t,
                                         pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCcsru2csr(handle, m, n, nnz, descrA, csrVal, csrRowPtr, csrColInd,
                                    info, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCcsru2csr(handle::cusparseHandle_t, m::Cint, n::Cint,
                                         nnz::Cint, descrA::cusparseMatDescr_t,
                                         csrVal::CuPtr{cuComplex}, csrRowPtr::CuPtr{Cint},
                                         csrColInd::CuPtr{Cint}, info::csru2csrInfo_t,
                                         pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZcsru2csr(handle, m, n, nnz, descrA, csrVal, csrRowPtr, csrColInd,
                                    info, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZcsru2csr(handle::cusparseHandle_t, m::Cint, n::Cint,
                                         nnz::Cint, descrA::cusparseMatDescr_t,
                                         csrVal::CuPtr{cuDoubleComplex},
                                         csrRowPtr::CuPtr{Cint}, csrColInd::CuPtr{Cint},
                                         info::csru2csrInfo_t,
                                         pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseScsr2csru(handle, m, n, nnz, descrA, csrVal, csrRowPtr, csrColInd,
                                    info, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseScsr2csru(handle::cusparseHandle_t, m::Cint, n::Cint,
                                         nnz::Cint, descrA::cusparseMatDescr_t,
                                         csrVal::CuPtr{Cfloat}, csrRowPtr::CuPtr{Cint},
                                         csrColInd::CuPtr{Cint}, info::csru2csrInfo_t,
                                         pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDcsr2csru(handle, m, n, nnz, descrA, csrVal, csrRowPtr, csrColInd,
                                    info, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDcsr2csru(handle::cusparseHandle_t, m::Cint, n::Cint,
                                         nnz::Cint, descrA::cusparseMatDescr_t,
                                         csrVal::CuPtr{Cdouble}, csrRowPtr::CuPtr{Cint},
                                         csrColInd::CuPtr{Cint}, info::csru2csrInfo_t,
                                         pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCcsr2csru(handle, m, n, nnz, descrA, csrVal, csrRowPtr, csrColInd,
                                    info, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseCcsr2csru(handle::cusparseHandle_t, m::Cint, n::Cint,
                                         nnz::Cint, descrA::cusparseMatDescr_t,
                                         csrVal::CuPtr{cuComplex}, csrRowPtr::CuPtr{Cint},
                                         csrColInd::CuPtr{Cint}, info::csru2csrInfo_t,
                                         pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseZcsr2csru(handle, m, n, nnz, descrA, csrVal, csrRowPtr, csrColInd,
                                    info, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseZcsr2csru(handle::cusparseHandle_t, m::Cint, n::Cint,
                                         nnz::Cint, descrA::cusparseMatDescr_t,
                                         csrVal::CuPtr{cuDoubleComplex},
                                         csrRowPtr::CuPtr{Cint}, csrColInd::CuPtr{Cint},
                                         info::csru2csrInfo_t,
                                         pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSpruneDense2csr_bufferSizeExt(handle, m, n, A, lda, threshold,
                                                        descrC, csrSortedValC,
                                                        csrSortedRowPtrC, csrSortedColIndC,
                                                        pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseSpruneDense2csr_bufferSizeExt(handle::cusparseHandle_t,
                                                             m::Cint, n::Cint,
                                                             A::CuPtr{Cfloat}, lda::Cint,
                                                             threshold::Ptr{Cfloat},
                                                             descrC::cusparseMatDescr_t,
                                                             csrSortedValC::CuPtr{Cfloat},
                                                             csrSortedRowPtrC::CuPtr{Cint},
                                                             csrSortedColIndC::CuPtr{Cint},
                                                             pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseDpruneDense2csr_bufferSizeExt(handle, m, n, A, lda, threshold,
                                                        descrC, csrSortedValC,
                                                        csrSortedRowPtrC, csrSortedColIndC,
                                                        pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseDpruneDense2csr_bufferSizeExt(handle::cusparseHandle_t,
                                                             m::Cint, n::Cint,
                                                             A::CuPtr{Cdouble}, lda::Cint,
                                                             threshold::Ptr{Cdouble},
                                                             descrC::cusparseMatDescr_t,
                                                             csrSortedValC::CuPtr{Cdouble},
                                                             csrSortedRowPtrC::CuPtr{Cint},
                                                             csrSortedColIndC::CuPtr{Cint},
                                                             pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseSpruneDense2csrNnz(handle, m, n, A, lda, threshold, descrC,
                                             csrRowPtrC, nnzTotalDevHostPtr, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSpruneDense2csrNnz(handle::cusparseHandle_t, m::Cint,
                                                  n::Cint, A::CuPtr{Cfloat}, lda::Cint,
                                                  threshold::Ptr{Cfloat},
                                                  descrC::cusparseMatDescr_t,
                                                  csrRowPtrC::CuPtr{Cint},
                                                  nnzTotalDevHostPtr::PtrOrCuPtr{Cint},
                                                  pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDpruneDense2csrNnz(handle, m, n, A, lda, threshold, descrC,
                                             csrSortedRowPtrC, nnzTotalDevHostPtr, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDpruneDense2csrNnz(handle::cusparseHandle_t, m::Cint,
                                                  n::Cint, A::CuPtr{Cdouble}, lda::Cint,
                                                  threshold::Ptr{Cdouble},
                                                  descrC::cusparseMatDescr_t,
                                                  csrSortedRowPtrC::CuPtr{Cint},
                                                  nnzTotalDevHostPtr::PtrOrCuPtr{Cint},
                                                  pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSpruneDense2csr(handle, m, n, A, lda, threshold, descrC,
                                          csrSortedValC, csrSortedRowPtrC, csrSortedColIndC,
                                          pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSpruneDense2csr(handle::cusparseHandle_t, m::Cint, n::Cint,
                                               A::CuPtr{Cfloat}, lda::Cint,
                                               threshold::Ptr{Cfloat},
                                               descrC::cusparseMatDescr_t,
                                               csrSortedValC::CuPtr{Cfloat},
                                               csrSortedRowPtrC::CuPtr{Cint},
                                               csrSortedColIndC::CuPtr{Cint},
                                               pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDpruneDense2csr(handle, m, n, A, lda, threshold, descrC,
                                          csrSortedValC, csrSortedRowPtrC, csrSortedColIndC,
                                          pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDpruneDense2csr(handle::cusparseHandle_t, m::Cint, n::Cint,
                                               A::CuPtr{Cdouble}, lda::Cint,
                                               threshold::Ptr{Cdouble},
                                               descrC::cusparseMatDescr_t,
                                               csrSortedValC::CuPtr{Cdouble},
                                               csrSortedRowPtrC::CuPtr{Cint},
                                               csrSortedColIndC::CuPtr{Cint},
                                               pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSpruneCsr2csr_bufferSizeExt(handle, m, n, nnzA, descrA,
                                                      csrSortedValA, csrSortedRowPtrA,
                                                      csrSortedColIndA, threshold, descrC,
                                                      csrSortedValC, csrSortedRowPtrC,
                                                      csrSortedColIndC, pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseSpruneCsr2csr_bufferSizeExt(handle::cusparseHandle_t,
                                                           m::Cint, n::Cint, nnzA::Cint,
                                                           descrA::cusparseMatDescr_t,
                                                           csrSortedValA::CuPtr{Cfloat},
                                                           csrSortedRowPtrA::CuPtr{Cint},
                                                           csrSortedColIndA::CuPtr{Cint},
                                                           threshold::Ptr{Cfloat},
                                                           descrC::cusparseMatDescr_t,
                                                           csrSortedValC::CuPtr{Cfloat},
                                                           csrSortedRowPtrC::CuPtr{Cint},
                                                           csrSortedColIndC::CuPtr{Cint},
                                                           pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseDpruneCsr2csr_bufferSizeExt(handle, m, n, nnzA, descrA,
                                                      csrSortedValA, csrSortedRowPtrA,
                                                      csrSortedColIndA, threshold, descrC,
                                                      csrSortedValC, csrSortedRowPtrC,
                                                      csrSortedColIndC, pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseDpruneCsr2csr_bufferSizeExt(handle::cusparseHandle_t,
                                                           m::Cint, n::Cint, nnzA::Cint,
                                                           descrA::cusparseMatDescr_t,
                                                           csrSortedValA::CuPtr{Cdouble},
                                                           csrSortedRowPtrA::CuPtr{Cint},
                                                           csrSortedColIndA::CuPtr{Cint},
                                                           threshold::Ptr{Cdouble},
                                                           descrC::cusparseMatDescr_t,
                                                           csrSortedValC::CuPtr{Cdouble},
                                                           csrSortedRowPtrC::CuPtr{Cint},
                                                           csrSortedColIndC::CuPtr{Cint},
                                                           pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseSpruneCsr2csrNnz(handle, m, n, nnzA, descrA, csrSortedValA,
                                           csrSortedRowPtrA, csrSortedColIndA, threshold,
                                           descrC, csrSortedRowPtrC, nnzTotalDevHostPtr,
                                           pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSpruneCsr2csrNnz(handle::cusparseHandle_t, m::Cint, n::Cint,
                                                nnzA::Cint, descrA::cusparseMatDescr_t,
                                                csrSortedValA::CuPtr{Cfloat},
                                                csrSortedRowPtrA::CuPtr{Cint},
                                                csrSortedColIndA::CuPtr{Cint},
                                                threshold::Ptr{Cfloat},
                                                descrC::cusparseMatDescr_t,
                                                csrSortedRowPtrC::CuPtr{Cint},
                                                nnzTotalDevHostPtr::PtrOrCuPtr{Cint},
                                                pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDpruneCsr2csrNnz(handle, m, n, nnzA, descrA, csrSortedValA,
                                           csrSortedRowPtrA, csrSortedColIndA, threshold,
                                           descrC, csrSortedRowPtrC, nnzTotalDevHostPtr,
                                           pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDpruneCsr2csrNnz(handle::cusparseHandle_t, m::Cint, n::Cint,
                                                nnzA::Cint, descrA::cusparseMatDescr_t,
                                                csrSortedValA::CuPtr{Cdouble},
                                                csrSortedRowPtrA::CuPtr{Cint},
                                                csrSortedColIndA::CuPtr{Cint},
                                                threshold::Ptr{Cdouble},
                                                descrC::cusparseMatDescr_t,
                                                csrSortedRowPtrC::CuPtr{Cint},
                                                nnzTotalDevHostPtr::PtrOrCuPtr{Cint},
                                                pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSpruneCsr2csr(handle, m, n, nnzA, descrA, csrSortedValA,
                                        csrSortedRowPtrA, csrSortedColIndA, threshold,
                                        descrC, csrSortedValC, csrSortedRowPtrC,
                                        csrSortedColIndC, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSpruneCsr2csr(handle::cusparseHandle_t, m::Cint, n::Cint,
                                             nnzA::Cint, descrA::cusparseMatDescr_t,
                                             csrSortedValA::CuPtr{Cfloat},
                                             csrSortedRowPtrA::CuPtr{Cint},
                                             csrSortedColIndA::CuPtr{Cint},
                                             threshold::Ptr{Cfloat},
                                             descrC::cusparseMatDescr_t,
                                             csrSortedValC::CuPtr{Cfloat},
                                             csrSortedRowPtrC::CuPtr{Cint},
                                             csrSortedColIndC::CuPtr{Cint},
                                             pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDpruneCsr2csr(handle, m, n, nnzA, descrA, csrSortedValA,
                                        csrSortedRowPtrA, csrSortedColIndA, threshold,
                                        descrC, csrSortedValC, csrSortedRowPtrC,
                                        csrSortedColIndC, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDpruneCsr2csr(handle::cusparseHandle_t, m::Cint, n::Cint,
                                             nnzA::Cint, descrA::cusparseMatDescr_t,
                                             csrSortedValA::CuPtr{Cdouble},
                                             csrSortedRowPtrA::CuPtr{Cint},
                                             csrSortedColIndA::CuPtr{Cint},
                                             threshold::Ptr{Cdouble},
                                             descrC::cusparseMatDescr_t,
                                             csrSortedValC::CuPtr{Cdouble},
                                             csrSortedRowPtrC::CuPtr{Cint},
                                             csrSortedColIndC::CuPtr{Cint},
                                             pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSpruneDense2csrByPercentage_bufferSizeExt(handle, m, n, A, lda,
                                                                    percentage, descrC,
                                                                    csrSortedValC,
                                                                    csrSortedRowPtrC,
                                                                    csrSortedColIndC, info,
                                                                    pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseSpruneDense2csrByPercentage_bufferSizeExt(handle::cusparseHandle_t,
                                                                         m::Cint, n::Cint,
                                                                         A::CuPtr{Cfloat},
                                                                         lda::Cint,
                                                                         percentage::Cfloat,
                                                                         descrC::cusparseMatDescr_t,
                                                                         csrSortedValC::CuPtr{Cfloat},
                                                                         csrSortedRowPtrC::CuPtr{Cint},
                                                                         csrSortedColIndC::CuPtr{Cint},
                                                                         info::pruneInfo_t,
                                                                         pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseDpruneDense2csrByPercentage_bufferSizeExt(handle, m, n, A, lda,
                                                                    percentage, descrC,
                                                                    csrSortedValC,
                                                                    csrSortedRowPtrC,
                                                                    csrSortedColIndC, info,
                                                                    pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseDpruneDense2csrByPercentage_bufferSizeExt(handle::cusparseHandle_t,
                                                                         m::Cint, n::Cint,
                                                                         A::CuPtr{Cdouble},
                                                                         lda::Cint,
                                                                         percentage::Cfloat,
                                                                         descrC::cusparseMatDescr_t,
                                                                         csrSortedValC::CuPtr{Cdouble},
                                                                         csrSortedRowPtrC::CuPtr{Cint},
                                                                         csrSortedColIndC::CuPtr{Cint},
                                                                         info::pruneInfo_t,
                                                                         pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseSpruneDense2csrNnzByPercentage(handle, m, n, A, lda, percentage,
                                                         descrC, csrRowPtrC,
                                                         nnzTotalDevHostPtr, info, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSpruneDense2csrNnzByPercentage(handle::cusparseHandle_t,
                                                              m::Cint, n::Cint,
                                                              A::CuPtr{Cfloat}, lda::Cint,
                                                              percentage::Cfloat,
                                                              descrC::cusparseMatDescr_t,
                                                              csrRowPtrC::CuPtr{Cint},
                                                              nnzTotalDevHostPtr::PtrOrCuPtr{Cint},
                                                              info::pruneInfo_t,
                                                              pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDpruneDense2csrNnzByPercentage(handle, m, n, A, lda, percentage,
                                                         descrC, csrRowPtrC,
                                                         nnzTotalDevHostPtr, info, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDpruneDense2csrNnzByPercentage(handle::cusparseHandle_t,
                                                              m::Cint, n::Cint,
                                                              A::CuPtr{Cdouble}, lda::Cint,
                                                              percentage::Cfloat,
                                                              descrC::cusparseMatDescr_t,
                                                              csrRowPtrC::CuPtr{Cint},
                                                              nnzTotalDevHostPtr::PtrOrCuPtr{Cint},
                                                              info::pruneInfo_t,
                                                              pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSpruneDense2csrByPercentage(handle, m, n, A, lda, percentage,
                                                      descrC, csrSortedValC,
                                                      csrSortedRowPtrC, csrSortedColIndC,
                                                      info, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSpruneDense2csrByPercentage(handle::cusparseHandle_t,
                                                           m::Cint, n::Cint,
                                                           A::CuPtr{Cfloat}, lda::Cint,
                                                           percentage::Cfloat,
                                                           descrC::cusparseMatDescr_t,
                                                           csrSortedValC::CuPtr{Cfloat},
                                                           csrSortedRowPtrC::CuPtr{Cint},
                                                           csrSortedColIndC::CuPtr{Cint},
                                                           info::pruneInfo_t,
                                                           pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDpruneDense2csrByPercentage(handle, m, n, A, lda, percentage,
                                                      descrC, csrSortedValC,
                                                      csrSortedRowPtrC, csrSortedColIndC,
                                                      info, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDpruneDense2csrByPercentage(handle::cusparseHandle_t,
                                                           m::Cint, n::Cint,
                                                           A::CuPtr{Cdouble}, lda::Cint,
                                                           percentage::Cfloat,
                                                           descrC::cusparseMatDescr_t,
                                                           csrSortedValC::CuPtr{Cdouble},
                                                           csrSortedRowPtrC::CuPtr{Cint},
                                                           csrSortedColIndC::CuPtr{Cint},
                                                           info::pruneInfo_t,
                                                           pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSpruneCsr2csrByPercentage_bufferSizeExt(handle, m, n, nnzA,
                                                                  descrA, csrSortedValA,
                                                                  csrSortedRowPtrA,
                                                                  csrSortedColIndA,
                                                                  percentage, descrC,
                                                                  csrSortedValC,
                                                                  csrSortedRowPtrC,
                                                                  csrSortedColIndC, info,
                                                                  pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseSpruneCsr2csrByPercentage_bufferSizeExt(handle::cusparseHandle_t,
                                                                       m::Cint, n::Cint,
                                                                       nnzA::Cint,
                                                                       descrA::cusparseMatDescr_t,
                                                                       csrSortedValA::CuPtr{Cfloat},
                                                                       csrSortedRowPtrA::CuPtr{Cint},
                                                                       csrSortedColIndA::CuPtr{Cint},
                                                                       percentage::Cfloat,
                                                                       descrC::cusparseMatDescr_t,
                                                                       csrSortedValC::CuPtr{Cfloat},
                                                                       csrSortedRowPtrC::CuPtr{Cint},
                                                                       csrSortedColIndC::CuPtr{Cint},
                                                                       info::pruneInfo_t,
                                                                       pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseDpruneCsr2csrByPercentage_bufferSizeExt(handle, m, n, nnzA,
                                                                  descrA, csrSortedValA,
                                                                  csrSortedRowPtrA,
                                                                  csrSortedColIndA,
                                                                  percentage, descrC,
                                                                  csrSortedValC,
                                                                  csrSortedRowPtrC,
                                                                  csrSortedColIndC, info,
                                                                  pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseDpruneCsr2csrByPercentage_bufferSizeExt(handle::cusparseHandle_t,
                                                                       m::Cint, n::Cint,
                                                                       nnzA::Cint,
                                                                       descrA::cusparseMatDescr_t,
                                                                       csrSortedValA::CuPtr{Cdouble},
                                                                       csrSortedRowPtrA::CuPtr{Cint},
                                                                       csrSortedColIndA::CuPtr{Cint},
                                                                       percentage::Cfloat,
                                                                       descrC::cusparseMatDescr_t,
                                                                       csrSortedValC::CuPtr{Cdouble},
                                                                       csrSortedRowPtrC::CuPtr{Cint},
                                                                       csrSortedColIndC::CuPtr{Cint},
                                                                       info::pruneInfo_t,
                                                                       pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseSpruneCsr2csrNnzByPercentage(handle, m, n, nnzA, descrA,
                                                       csrSortedValA, csrSortedRowPtrA,
                                                       csrSortedColIndA, percentage, descrC,
                                                       csrSortedRowPtrC, nnzTotalDevHostPtr,
                                                       info, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSpruneCsr2csrNnzByPercentage(handle::cusparseHandle_t,
                                                            m::Cint, n::Cint, nnzA::Cint,
                                                            descrA::cusparseMatDescr_t,
                                                            csrSortedValA::CuPtr{Cfloat},
                                                            csrSortedRowPtrA::CuPtr{Cint},
                                                            csrSortedColIndA::CuPtr{Cint},
                                                            percentage::Cfloat,
                                                            descrC::cusparseMatDescr_t,
                                                            csrSortedRowPtrC::CuPtr{Cint},
                                                            nnzTotalDevHostPtr::PtrOrCuPtr{Cint},
                                                            info::pruneInfo_t,
                                                            pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDpruneCsr2csrNnzByPercentage(handle, m, n, nnzA, descrA,
                                                       csrSortedValA, csrSortedRowPtrA,
                                                       csrSortedColIndA, percentage, descrC,
                                                       csrSortedRowPtrC, nnzTotalDevHostPtr,
                                                       info, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDpruneCsr2csrNnzByPercentage(handle::cusparseHandle_t,
                                                            m::Cint, n::Cint, nnzA::Cint,
                                                            descrA::cusparseMatDescr_t,
                                                            csrSortedValA::CuPtr{Cdouble},
                                                            csrSortedRowPtrA::CuPtr{Cint},
                                                            csrSortedColIndA::CuPtr{Cint},
                                                            percentage::Cfloat,
                                                            descrC::cusparseMatDescr_t,
                                                            csrSortedRowPtrC::CuPtr{Cint},
                                                            nnzTotalDevHostPtr::PtrOrCuPtr{Cint},
                                                            info::pruneInfo_t,
                                                            pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSpruneCsr2csrByPercentage(handle, m, n, nnzA, descrA,
                                                    csrSortedValA, csrSortedRowPtrA,
                                                    csrSortedColIndA, percentage, descrC,
                                                    csrSortedValC, csrSortedRowPtrC,
                                                    csrSortedColIndC, info, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSpruneCsr2csrByPercentage(handle::cusparseHandle_t, m::Cint,
                                                         n::Cint, nnzA::Cint,
                                                         descrA::cusparseMatDescr_t,
                                                         csrSortedValA::CuPtr{Cfloat},
                                                         csrSortedRowPtrA::CuPtr{Cint},
                                                         csrSortedColIndA::CuPtr{Cint},
                                                         percentage::Cfloat,
                                                         descrC::cusparseMatDescr_t,
                                                         csrSortedValC::CuPtr{Cfloat},
                                                         csrSortedRowPtrC::CuPtr{Cint},
                                                         csrSortedColIndC::CuPtr{Cint},
                                                         info::pruneInfo_t,
                                                         pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDpruneCsr2csrByPercentage(handle, m, n, nnzA, descrA,
                                                    csrSortedValA, csrSortedRowPtrA,
                                                    csrSortedColIndA, percentage, descrC,
                                                    csrSortedValC, csrSortedRowPtrC,
                                                    csrSortedColIndC, info, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDpruneCsr2csrByPercentage(handle::cusparseHandle_t, m::Cint,
                                                         n::Cint, nnzA::Cint,
                                                         descrA::cusparseMatDescr_t,
                                                         csrSortedValA::CuPtr{Cdouble},
                                                         csrSortedRowPtrA::CuPtr{Cint},
                                                         csrSortedColIndA::CuPtr{Cint},
                                                         percentage::Cfloat,
                                                         descrC::cusparseMatDescr_t,
                                                         csrSortedValC::CuPtr{Cdouble},
                                                         csrSortedRowPtrC::CuPtr{Cint},
                                                         csrSortedColIndC::CuPtr{Cint},
                                                         info::pruneInfo_t,
                                                         pBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@cenum cusparseCsr2CscAlg_t::UInt32 begin
    CUSPARSE_CSR2CSC_ALG1 = 1
    CUSPARSE_CSR2CSC_ALG2 = 2
end

@checked function cusparseCsr2cscEx2(handle, m, n, nnz, csrVal, csrRowPtr, csrColInd,
                                     cscVal, cscColPtr, cscRowInd, valType, copyValues,
                                     idxBase, alg, buffer)
    initialize_context()
    @ccall libcusparse.cusparseCsr2cscEx2(handle::cusparseHandle_t, m::Cint, n::Cint,
                                          nnz::Cint, csrVal::CuPtr{Cvoid},
                                          csrRowPtr::CuPtr{Cint}, csrColInd::CuPtr{Cint},
                                          cscVal::CuPtr{Cvoid}, cscColPtr::CuPtr{Cint},
                                          cscRowInd::CuPtr{Cint}, valType::cudaDataType,
                                          copyValues::cusparseAction_t,
                                          idxBase::cusparseIndexBase_t,
                                          alg::cusparseCsr2CscAlg_t,
                                          buffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCsr2cscEx2_bufferSize(handle, m, n, nnz, csrVal, csrRowPtr,
                                                csrColInd, cscVal, cscColPtr, cscRowInd,
                                                valType, copyValues, idxBase, alg,
                                                bufferSize)
    initialize_context()
    @ccall libcusparse.cusparseCsr2cscEx2_bufferSize(handle::cusparseHandle_t, m::Cint,
                                                     n::Cint, nnz::Cint,
                                                     csrVal::CuPtr{Cvoid},
                                                     csrRowPtr::CuPtr{Cint},
                                                     csrColInd::CuPtr{Cint},
                                                     cscVal::CuPtr{Cvoid},
                                                     cscColPtr::CuPtr{Cint},
                                                     cscRowInd::CuPtr{Cint},
                                                     valType::cudaDataType,
                                                     copyValues::cusparseAction_t,
                                                     idxBase::cusparseIndexBase_t,
                                                     alg::cusparseCsr2CscAlg_t,
                                                     bufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@cenum cusparseFormat_t::UInt32 begin
    CUSPARSE_FORMAT_CSR = 1
    CUSPARSE_FORMAT_CSC = 2
    CUSPARSE_FORMAT_COO = 3
    CUSPARSE_FORMAT_COO_AOS = 4
    CUSPARSE_FORMAT_BLOCKED_ELL = 5
end

@cenum cusparseOrder_t::UInt32 begin
    CUSPARSE_ORDER_COL = 1
    CUSPARSE_ORDER_ROW = 2
end

@cenum cusparseIndexType_t::UInt32 begin
    CUSPARSE_INDEX_16U = 1
    CUSPARSE_INDEX_32I = 2
    CUSPARSE_INDEX_64I = 3
end

mutable struct cusparseSpVecDescr end

mutable struct cusparseDnVecDescr end

mutable struct cusparseSpMatDescr end

mutable struct cusparseDnMatDescr end

const cusparseSpVecDescr_t = Ptr{cusparseSpVecDescr}

const cusparseDnVecDescr_t = Ptr{cusparseDnVecDescr}

const cusparseSpMatDescr_t = Ptr{cusparseSpMatDescr}

const cusparseDnMatDescr_t = Ptr{cusparseDnMatDescr}

@checked function cusparseCreateSpVec(spVecDescr, size, nnz, indices, values, idxType,
                                      idxBase, valueType)
    initialize_context()
    @ccall libcusparse.cusparseCreateSpVec(spVecDescr::Ptr{cusparseSpVecDescr_t},
                                           size::Int64, nnz::Int64, indices::CuPtr{Cvoid},
                                           values::CuPtr{Cvoid},
                                           idxType::cusparseIndexType_t,
                                           idxBase::cusparseIndexBase_t,
                                           valueType::cudaDataType)::cusparseStatus_t
end

@checked function cusparseDestroySpVec(spVecDescr)
    initialize_context()
    @ccall libcusparse.cusparseDestroySpVec(spVecDescr::cusparseSpVecDescr_t)::cusparseStatus_t
end

@checked function cusparseSpVecGet(spVecDescr, size, nnz, indices, values, idxType, idxBase,
                                   valueType)
    initialize_context()
    @ccall libcusparse.cusparseSpVecGet(spVecDescr::cusparseSpVecDescr_t, size::Ptr{Int64},
                                        nnz::Ptr{Int64}, indices::CuPtr{Ptr{Cvoid}},
                                        values::CuPtr{Ptr{Cvoid}},
                                        idxType::Ptr{cusparseIndexType_t},
                                        idxBase::Ptr{cusparseIndexBase_t},
                                        valueType::Ptr{cudaDataType})::cusparseStatus_t
end

@checked function cusparseSpVecGetIndexBase(spVecDescr, idxBase)
    initialize_context()
    @ccall libcusparse.cusparseSpVecGetIndexBase(spVecDescr::cusparseSpVecDescr_t,
                                                 idxBase::Ptr{cusparseIndexBase_t})::cusparseStatus_t
end

@checked function cusparseSpVecGetValues(spVecDescr, values)
    initialize_context()
    @ccall libcusparse.cusparseSpVecGetValues(spVecDescr::cusparseSpVecDescr_t,
                                              values::CuPtr{Ptr{Cvoid}})::cusparseStatus_t
end

@checked function cusparseSpVecSetValues(spVecDescr, values)
    initialize_context()
    @ccall libcusparse.cusparseSpVecSetValues(spVecDescr::cusparseSpVecDescr_t,
                                              values::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCreateDnVec(dnVecDescr, size, values, valueType)
    initialize_context()
    @ccall libcusparse.cusparseCreateDnVec(dnVecDescr::Ptr{cusparseDnVecDescr_t},
                                           size::Int64, values::CuPtr{Cvoid},
                                           valueType::cudaDataType)::cusparseStatus_t
end

@checked function cusparseDestroyDnVec(dnVecDescr)
    initialize_context()
    @ccall libcusparse.cusparseDestroyDnVec(dnVecDescr::cusparseDnVecDescr_t)::cusparseStatus_t
end

@checked function cusparseDnVecGet(dnVecDescr, size, values, valueType)
    initialize_context()
    @ccall libcusparse.cusparseDnVecGet(dnVecDescr::cusparseDnVecDescr_t, size::Ptr{Int64},
                                        values::CuPtr{Ptr{Cvoid}},
                                        valueType::Ptr{cudaDataType})::cusparseStatus_t
end

@checked function cusparseDnVecGetValues(dnVecDescr, values)
    initialize_context()
    @ccall libcusparse.cusparseDnVecGetValues(dnVecDescr::cusparseDnVecDescr_t,
                                              values::CuPtr{Ptr{Cvoid}})::cusparseStatus_t
end

@checked function cusparseDnVecSetValues(dnVecDescr, values)
    initialize_context()
    @ccall libcusparse.cusparseDnVecSetValues(dnVecDescr::cusparseDnVecDescr_t,
                                              values::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDestroySpMat(spMatDescr)
    initialize_context()
    @ccall libcusparse.cusparseDestroySpMat(spMatDescr::cusparseSpMatDescr_t)::cusparseStatus_t
end

@checked function cusparseSpMatGetFormat(spMatDescr, format)
    initialize_context()
    @ccall libcusparse.cusparseSpMatGetFormat(spMatDescr::cusparseSpMatDescr_t,
                                              format::Ptr{cusparseFormat_t})::cusparseStatus_t
end

@checked function cusparseSpMatGetIndexBase(spMatDescr, idxBase)
    initialize_context()
    @ccall libcusparse.cusparseSpMatGetIndexBase(spMatDescr::cusparseSpMatDescr_t,
                                                 idxBase::Ptr{cusparseIndexBase_t})::cusparseStatus_t
end

@checked function cusparseSpMatGetValues(spMatDescr, values)
    initialize_context()
    @ccall libcusparse.cusparseSpMatGetValues(spMatDescr::cusparseSpMatDescr_t,
                                              values::CuPtr{Ptr{Cvoid}})::cusparseStatus_t
end

@checked function cusparseSpMatSetValues(spMatDescr, values)
    initialize_context()
    @ccall libcusparse.cusparseSpMatSetValues(spMatDescr::cusparseSpMatDescr_t,
                                              values::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSpMatGetSize(spMatDescr, rows, cols, nnz)
    initialize_context()
    @ccall libcusparse.cusparseSpMatGetSize(spMatDescr::cusparseSpMatDescr_t,
                                            rows::Ptr{Int64}, cols::Ptr{Int64},
                                            nnz::Ptr{Int64})::cusparseStatus_t
end

@checked function cusparseSpMatSetStridedBatch(spMatDescr, batchCount)
    initialize_context()
    @ccall libcusparse.cusparseSpMatSetStridedBatch(spMatDescr::cusparseSpMatDescr_t,
                                                    batchCount::Cint)::cusparseStatus_t
end

@checked function cusparseSpMatGetStridedBatch(spMatDescr, batchCount)
    initialize_context()
    @ccall libcusparse.cusparseSpMatGetStridedBatch(spMatDescr::cusparseSpMatDescr_t,
                                                    batchCount::Ptr{Cint})::cusparseStatus_t
end

@checked function cusparseCooSetStridedBatch(spMatDescr, batchCount, batchStride)
    initialize_context()
    @ccall libcusparse.cusparseCooSetStridedBatch(spMatDescr::cusparseSpMatDescr_t,
                                                  batchCount::Cint,
                                                  batchStride::Int64)::cusparseStatus_t
end

@checked function cusparseCsrSetStridedBatch(spMatDescr, batchCount, offsetsBatchStride,
                                             columnsValuesBatchStride)
    initialize_context()
    @ccall libcusparse.cusparseCsrSetStridedBatch(spMatDescr::cusparseSpMatDescr_t,
                                                  batchCount::Cint,
                                                  offsetsBatchStride::Int64,
                                                  columnsValuesBatchStride::Int64)::cusparseStatus_t
end

@cenum cusparseSpMatAttribute_t::UInt32 begin
    CUSPARSE_SPMAT_FILL_MODE = 0
    CUSPARSE_SPMAT_DIAG_TYPE = 1
end

@checked function cusparseSpMatGetAttribute(spMatDescr, attribute, data, dataSize)
    initialize_context()
    @ccall libcusparse.cusparseSpMatGetAttribute(spMatDescr::cusparseSpMatDescr_t,
                                                 attribute::cusparseSpMatAttribute_t,
                                                 data::Ptr{Cvoid},
                                                 dataSize::Csize_t)::cusparseStatus_t
end

@checked function cusparseSpMatSetAttribute(spMatDescr, attribute, data, dataSize)
    initialize_context()
    @ccall libcusparse.cusparseSpMatSetAttribute(spMatDescr::cusparseSpMatDescr_t,
                                                 attribute::cusparseSpMatAttribute_t,
                                                 data::Ptr{Cvoid},
                                                 dataSize::Csize_t)::cusparseStatus_t
end

@checked function cusparseCreateCsr(spMatDescr, rows, cols, nnz, csrRowOffsets, csrColInd,
                                    csrValues, csrRowOffsetsType, csrColIndType, idxBase,
                                    valueType)
    initialize_context()
    @ccall libcusparse.cusparseCreateCsr(spMatDescr::Ptr{cusparseSpMatDescr_t}, rows::Int64,
                                         cols::Int64, nnz::Int64,
                                         csrRowOffsets::CuPtr{Cvoid},
                                         csrColInd::CuPtr{Cvoid}, csrValues::CuPtr{Cvoid},
                                         csrRowOffsetsType::cusparseIndexType_t,
                                         csrColIndType::cusparseIndexType_t,
                                         idxBase::cusparseIndexBase_t,
                                         valueType::cudaDataType)::cusparseStatus_t
end

@checked function cusparseCreateCsc(spMatDescr, rows, cols, nnz, cscColOffsets, cscRowInd,
                                    cscValues, cscColOffsetsType, cscRowIndType, idxBase,
                                    valueType)
    initialize_context()
    @ccall libcusparse.cusparseCreateCsc(spMatDescr::Ptr{cusparseSpMatDescr_t}, rows::Int64,
                                         cols::Int64, nnz::Int64,
                                         cscColOffsets::CuPtr{Cvoid},
                                         cscRowInd::CuPtr{Cvoid}, cscValues::CuPtr{Cvoid},
                                         cscColOffsetsType::cusparseIndexType_t,
                                         cscRowIndType::cusparseIndexType_t,
                                         idxBase::cusparseIndexBase_t,
                                         valueType::cudaDataType)::cusparseStatus_t
end

@checked function cusparseCsrGet(spMatDescr, rows, cols, nnz, csrRowOffsets, csrColInd,
                                 csrValues, csrRowOffsetsType, csrColIndType, idxBase,
                                 valueType)
    initialize_context()
    @ccall libcusparse.cusparseCsrGet(spMatDescr::cusparseSpMatDescr_t, rows::Ptr{Int64},
                                      cols::Ptr{Int64}, nnz::Ptr{Int64},
                                      csrRowOffsets::CuPtr{Ptr{Cvoid}},
                                      csrColInd::CuPtr{Ptr{Cvoid}},
                                      csrValues::CuPtr{Ptr{Cvoid}},
                                      csrRowOffsetsType::Ptr{cusparseIndexType_t},
                                      csrColIndType::Ptr{cusparseIndexType_t},
                                      idxBase::Ptr{cusparseIndexBase_t},
                                      valueType::Ptr{cudaDataType})::cusparseStatus_t
end

@checked function cusparseCscGet(spMatDescr, rows, cols, nnz, cscColOffsets, cscRowInd,
                                 cscValues, cscColOffsetsType, cscRowIndType, idxBase,
                                 valueType)
    initialize_context()
    @ccall libcusparse.cusparseCscGet(spMatDescr::cusparseSpMatDescr_t, rows::Ptr{Int64},
                                      cols::Ptr{Int64}, nnz::Ptr{Int64},
                                      cscColOffsets::Ptr{Ptr{Cvoid}},
                                      cscRowInd::Ptr{Ptr{Cvoid}},
                                      cscValues::Ptr{Ptr{Cvoid}},
                                      cscColOffsetsType::Ptr{cusparseIndexType_t},
                                      cscRowIndType::Ptr{cusparseIndexType_t},
                                      idxBase::Ptr{cusparseIndexBase_t},
                                      valueType::Ptr{cudaDataType})::cusparseStatus_t
end

@checked function cusparseCsrSetPointers(spMatDescr, csrRowOffsets, csrColInd, csrValues)
    initialize_context()
    @ccall libcusparse.cusparseCsrSetPointers(spMatDescr::cusparseSpMatDescr_t,
                                              csrRowOffsets::CuPtr{Cvoid},
                                              csrColInd::CuPtr{Cvoid},
                                              csrValues::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCscSetPointers(spMatDescr, cscColOffsets, cscRowInd, cscValues)
    initialize_context()
    @ccall libcusparse.cusparseCscSetPointers(spMatDescr::cusparseSpMatDescr_t,
                                              cscColOffsets::CuPtr{Cvoid},
                                              cscRowInd::CuPtr{Cvoid},
                                              cscValues::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCreateCoo(spMatDescr, rows, cols, nnz, cooRowInd, cooColInd,
                                    cooValues, cooIdxType, idxBase, valueType)
    initialize_context()
    @ccall libcusparse.cusparseCreateCoo(spMatDescr::Ptr{cusparseSpMatDescr_t}, rows::Int64,
                                         cols::Int64, nnz::Int64, cooRowInd::CuPtr{Cvoid},
                                         cooColInd::CuPtr{Cvoid}, cooValues::CuPtr{Cvoid},
                                         cooIdxType::cusparseIndexType_t,
                                         idxBase::cusparseIndexBase_t,
                                         valueType::cudaDataType)::cusparseStatus_t
end

@checked function cusparseCreateCooAoS(spMatDescr, rows, cols, nnz, cooInd, cooValues,
                                       cooIdxType, idxBase, valueType)
    initialize_context()
    @ccall libcusparse.cusparseCreateCooAoS(spMatDescr::Ptr{cusparseSpMatDescr_t},
                                            rows::Int64, cols::Int64, nnz::Int64,
                                            cooInd::CuPtr{Cvoid}, cooValues::CuPtr{Cvoid},
                                            cooIdxType::cusparseIndexType_t,
                                            idxBase::cusparseIndexBase_t,
                                            valueType::cudaDataType)::cusparseStatus_t
end

@checked function cusparseCooGet(spMatDescr, rows, cols, nnz, cooRowInd, cooColInd,
                                 cooValues, idxType, idxBase, valueType)
    initialize_context()
    @ccall libcusparse.cusparseCooGet(spMatDescr::cusparseSpMatDescr_t, rows::Ptr{Int64},
                                      cols::Ptr{Int64}, nnz::Ptr{Int64},
                                      cooRowInd::CuPtr{Ptr{Cvoid}},
                                      cooColInd::CuPtr{Ptr{Cvoid}},
                                      cooValues::CuPtr{Ptr{Cvoid}},
                                      idxType::Ptr{cusparseIndexType_t},
                                      idxBase::Ptr{cusparseIndexBase_t},
                                      valueType::Ptr{cudaDataType})::cusparseStatus_t
end

@checked function cusparseCooAoSGet(spMatDescr, rows, cols, nnz, cooInd, cooValues, idxType,
                                    idxBase, valueType)
    initialize_context()
    @ccall libcusparse.cusparseCooAoSGet(spMatDescr::cusparseSpMatDescr_t, rows::Ptr{Int64},
                                         cols::Ptr{Int64}, nnz::Ptr{Int64},
                                         cooInd::CuPtr{Ptr{Cvoid}},
                                         cooValues::CuPtr{Ptr{Cvoid}},
                                         idxType::Ptr{cusparseIndexType_t},
                                         idxBase::Ptr{cusparseIndexBase_t},
                                         valueType::Ptr{cudaDataType})::cusparseStatus_t
end

@checked function cusparseCooSetPointers(spMatDescr, cooRows, cooColumns, cooValues)
    initialize_context()
    @ccall libcusparse.cusparseCooSetPointers(spMatDescr::cusparseSpMatDescr_t,
                                              cooRows::CuPtr{Cvoid},
                                              cooColumns::CuPtr{Cvoid},
                                              cooValues::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseCreateBlockedEll(spMatDescr, rows, cols, ellBlockSize, ellCols,
                                           ellColInd, ellValue, ellIdxType, idxBase,
                                           valueType)
    initialize_context()
    @ccall libcusparse.cusparseCreateBlockedEll(spMatDescr::Ptr{cusparseSpMatDescr_t},
                                                rows::Int64, cols::Int64,
                                                ellBlockSize::Int64, ellCols::Int64,
                                                ellColInd::CuPtr{Cvoid},
                                                ellValue::CuPtr{Cvoid},
                                                ellIdxType::cusparseIndexType_t,
                                                idxBase::cusparseIndexBase_t,
                                                valueType::cudaDataType)::cusparseStatus_t
end

@checked function cusparseBlockedEllGet(spMatDescr, rows, cols, ellBlockSize, ellCols,
                                        ellColInd, ellValue, ellIdxType, idxBase, valueType)
    initialize_context()
    @ccall libcusparse.cusparseBlockedEllGet(spMatDescr::cusparseSpMatDescr_t,
                                             rows::Ptr{Int64}, cols::Ptr{Int64},
                                             ellBlockSize::Ptr{Int64}, ellCols::Ptr{Int64},
                                             ellColInd::CuPtr{Ptr{Cvoid}},
                                             ellValue::CuPtr{Ptr{Cvoid}},
                                             ellIdxType::Ptr{cusparseIndexType_t},
                                             idxBase::Ptr{cusparseIndexBase_t},
                                             valueType::Ptr{cudaDataType})::cusparseStatus_t
end

@checked function cusparseCreateDnMat(dnMatDescr, rows, cols, ld, values, valueType, order)
    initialize_context()
    @ccall libcusparse.cusparseCreateDnMat(dnMatDescr::Ptr{cusparseDnMatDescr_t},
                                           rows::Int64, cols::Int64, ld::Int64,
                                           values::CuPtr{Cvoid}, valueType::cudaDataType,
                                           order::cusparseOrder_t)::cusparseStatus_t
end

@checked function cusparseDestroyDnMat(dnMatDescr)
    initialize_context()
    @ccall libcusparse.cusparseDestroyDnMat(dnMatDescr::cusparseDnMatDescr_t)::cusparseStatus_t
end

@checked function cusparseDnMatGet(dnMatDescr, rows, cols, ld, values, type, order)
    initialize_context()
    @ccall libcusparse.cusparseDnMatGet(dnMatDescr::cusparseDnMatDescr_t, rows::Ptr{Int64},
                                        cols::Ptr{Int64}, ld::Ptr{Int64},
                                        values::CuPtr{Ptr{Cvoid}}, type::Ptr{cudaDataType},
                                        order::Ptr{cusparseOrder_t})::cusparseStatus_t
end

@checked function cusparseDnMatGetValues(dnMatDescr, values)
    initialize_context()
    @ccall libcusparse.cusparseDnMatGetValues(dnMatDescr::cusparseDnMatDescr_t,
                                              values::CuPtr{Ptr{Cvoid}})::cusparseStatus_t
end

@checked function cusparseDnMatSetValues(dnMatDescr, values)
    initialize_context()
    @ccall libcusparse.cusparseDnMatSetValues(dnMatDescr::cusparseDnMatDescr_t,
                                              values::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDnMatSetStridedBatch(dnMatDescr, batchCount, batchStride)
    initialize_context()
    @ccall libcusparse.cusparseDnMatSetStridedBatch(dnMatDescr::cusparseDnMatDescr_t,
                                                    batchCount::Cint,
                                                    batchStride::Int64)::cusparseStatus_t
end

@checked function cusparseDnMatGetStridedBatch(dnMatDescr, batchCount, batchStride)
    initialize_context()
    @ccall libcusparse.cusparseDnMatGetStridedBatch(dnMatDescr::cusparseDnMatDescr_t,
                                                    batchCount::Ptr{Cint},
                                                    batchStride::Ptr{Int64})::cusparseStatus_t
end

@checked function cusparseAxpby(handle, alpha, vecX, beta, vecY)
    initialize_context()
    @ccall libcusparse.cusparseAxpby(handle::cusparseHandle_t, alpha::PtrOrCuPtr{Cvoid},
                                     vecX::cusparseSpVecDescr_t, beta::PtrOrCuPtr{Cvoid},
                                     vecY::cusparseDnVecDescr_t)::cusparseStatus_t
end

@checked function cusparseGather(handle, vecY, vecX)
    initialize_context()
    @ccall libcusparse.cusparseGather(handle::cusparseHandle_t, vecY::cusparseDnVecDescr_t,
                                      vecX::cusparseSpVecDescr_t)::cusparseStatus_t
end

@checked function cusparseScatter(handle, vecX, vecY)
    initialize_context()
    @ccall libcusparse.cusparseScatter(handle::cusparseHandle_t, vecX::cusparseSpVecDescr_t,
                                       vecY::cusparseDnVecDescr_t)::cusparseStatus_t
end

@checked function cusparseRot(handle, c_coeff, s_coeff, vecX, vecY)
    initialize_context()
    @ccall libcusparse.cusparseRot(handle::cusparseHandle_t, c_coeff::PtrOrCuPtr{Cvoid},
                                   s_coeff::PtrOrCuPtr{Cvoid}, vecX::cusparseSpVecDescr_t,
                                   vecY::cusparseDnVecDescr_t)::cusparseStatus_t
end

@checked function cusparseSpVV_bufferSize(handle, opX, vecX, vecY, result, computeType,
                                          bufferSize)
    initialize_context()
    @ccall libcusparse.cusparseSpVV_bufferSize(handle::cusparseHandle_t,
                                               opX::cusparseOperation_t,
                                               vecX::cusparseSpVecDescr_t,
                                               vecY::cusparseDnVecDescr_t,
                                               result::PtrOrCuPtr{Cvoid},
                                               computeType::cudaDataType,
                                               bufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseSpVV(handle, opX, vecX, vecY, result, computeType, externalBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSpVV(handle::cusparseHandle_t, opX::cusparseOperation_t,
                                    vecX::cusparseSpVecDescr_t, vecY::cusparseDnVecDescr_t,
                                    result::PtrOrCuPtr{Cvoid}, computeType::cudaDataType,
                                    externalBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@cenum cusparseSparseToDenseAlg_t::UInt32 begin
    CUSPARSE_SPARSETODENSE_ALG_DEFAULT = 0
end

@checked function cusparseSparseToDense_bufferSize(handle, matA, matB, alg, bufferSize)
    initialize_context()
    @ccall libcusparse.cusparseSparseToDense_bufferSize(handle::cusparseHandle_t,
                                                        matA::cusparseSpMatDescr_t,
                                                        matB::cusparseDnMatDescr_t,
                                                        alg::cusparseSparseToDenseAlg_t,
                                                        bufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseSparseToDense(handle, matA, matB, alg, externalBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSparseToDense(handle::cusparseHandle_t,
                                             matA::cusparseSpMatDescr_t,
                                             matB::cusparseDnMatDescr_t,
                                             alg::cusparseSparseToDenseAlg_t,
                                             externalBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@cenum cusparseDenseToSparseAlg_t::UInt32 begin
    CUSPARSE_DENSETOSPARSE_ALG_DEFAULT = 0
end

@checked function cusparseDenseToSparse_bufferSize(handle, matA, matB, alg, bufferSize)
    initialize_context()
    @ccall libcusparse.cusparseDenseToSparse_bufferSize(handle::cusparseHandle_t,
                                                        matA::cusparseDnMatDescr_t,
                                                        matB::cusparseSpMatDescr_t,
                                                        alg::cusparseDenseToSparseAlg_t,
                                                        bufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseDenseToSparse_analysis(handle, matA, matB, alg, externalBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDenseToSparse_analysis(handle::cusparseHandle_t,
                                                      matA::cusparseDnMatDescr_t,
                                                      matB::cusparseSpMatDescr_t,
                                                      alg::cusparseDenseToSparseAlg_t,
                                                      externalBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseDenseToSparse_convert(handle, matA, matB, alg, externalBuffer)
    initialize_context()
    @ccall libcusparse.cusparseDenseToSparse_convert(handle::cusparseHandle_t,
                                                     matA::cusparseDnMatDescr_t,
                                                     matB::cusparseSpMatDescr_t,
                                                     alg::cusparseDenseToSparseAlg_t,
                                                     externalBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@cenum cusparseSpMVAlg_t::UInt32 begin
    CUSPARSE_MV_ALG_DEFAULT = 0
    CUSPARSE_COOMV_ALG = 1
    CUSPARSE_CSRMV_ALG1 = 2
    CUSPARSE_CSRMV_ALG2 = 3
    CUSPARSE_SPMV_ALG_DEFAULT = 0
    CUSPARSE_SPMV_CSR_ALG1 = 2
    CUSPARSE_SPMV_CSR_ALG2 = 3
    CUSPARSE_SPMV_COO_ALG1 = 1
    CUSPARSE_SPMV_COO_ALG2 = 4
end

@checked function cusparseSpMV(handle, opA, alpha, matA, vecX, beta, vecY, computeType, alg,
                               externalBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSpMV(handle::cusparseHandle_t, opA::cusparseOperation_t,
                                    alpha::PtrOrCuPtr{Cvoid}, matA::cusparseSpMatDescr_t,
                                    vecX::cusparseDnVecDescr_t, beta::PtrOrCuPtr{Cvoid},
                                    vecY::cusparseDnVecDescr_t, computeType::cudaDataType,
                                    alg::cusparseSpMVAlg_t,
                                    externalBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSpMV_bufferSize(handle, opA, alpha, matA, vecX, beta, vecY,
                                          computeType, alg, bufferSize)
    initialize_context()
    @ccall libcusparse.cusparseSpMV_bufferSize(handle::cusparseHandle_t,
                                               opA::cusparseOperation_t, alpha::Ptr{Cvoid},
                                               matA::cusparseSpMatDescr_t,
                                               vecX::cusparseDnVecDescr_t, beta::Ptr{Cvoid},
                                               vecY::cusparseDnVecDescr_t,
                                               computeType::cudaDataType,
                                               alg::cusparseSpMVAlg_t,
                                               bufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@cenum cusparseSpSVAlg_t::UInt32 begin
    CUSPARSE_SPSV_ALG_DEFAULT = 0
end

mutable struct cusparseSpSVDescr end

const cusparseSpSVDescr_t = Ptr{cusparseSpSVDescr}

@checked function cusparseSpSV_createDescr(descr)
    initialize_context()
    @ccall libcusparse.cusparseSpSV_createDescr(descr::Ptr{cusparseSpSVDescr_t})::cusparseStatus_t
end

@checked function cusparseSpSV_destroyDescr(descr)
    initialize_context()
    @ccall libcusparse.cusparseSpSV_destroyDescr(descr::cusparseSpSVDescr_t)::cusparseStatus_t
end

@checked function cusparseSpSV_bufferSize(handle, opA, alpha, matA, vecX, vecY, computeType,
                                          alg, spsvDescr, bufferSize)
    initialize_context()
    @ccall libcusparse.cusparseSpSV_bufferSize(handle::cusparseHandle_t,
                                               opA::cusparseOperation_t, alpha::Ptr{Cvoid},
                                               matA::cusparseSpMatDescr_t,
                                               vecX::cusparseDnVecDescr_t,
                                               vecY::cusparseDnVecDescr_t,
                                               computeType::cudaDataType,
                                               alg::cusparseSpSVAlg_t,
                                               spsvDescr::cusparseSpSVDescr_t,
                                               bufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseSpSV_analysis(handle, opA, alpha, matA, vecX, vecY, computeType,
                                        alg, spsvDescr, externalBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSpSV_analysis(handle::cusparseHandle_t,
                                             opA::cusparseOperation_t, alpha::Ptr{Cvoid},
                                             matA::cusparseSpMatDescr_t,
                                             vecX::cusparseDnVecDescr_t,
                                             vecY::cusparseDnVecDescr_t,
                                             computeType::cudaDataType,
                                             alg::cusparseSpSVAlg_t,
                                             spsvDescr::cusparseSpSVDescr_t,
                                             externalBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSpSV_solve(handle, opA, alpha, matA, vecX, vecY, computeType, alg,
                                     spsvDescr)
    initialize_context()
    @ccall libcusparse.cusparseSpSV_solve(handle::cusparseHandle_t,
                                          opA::cusparseOperation_t, alpha::Ptr{Cvoid},
                                          matA::cusparseSpMatDescr_t,
                                          vecX::cusparseDnVecDescr_t,
                                          vecY::cusparseDnVecDescr_t,
                                          computeType::cudaDataType, alg::cusparseSpSVAlg_t,
                                          spsvDescr::cusparseSpSVDescr_t)::cusparseStatus_t
end

@cenum cusparseSpSMAlg_t::UInt32 begin
    CUSPARSE_SPSM_ALG_DEFAULT = 0
end

mutable struct cusparseSpSMDescr end

const cusparseSpSMDescr_t = Ptr{cusparseSpSMDescr}

@checked function cusparseSpSM_createDescr(descr)
    initialize_context()
    @ccall libcusparse.cusparseSpSM_createDescr(descr::Ptr{cusparseSpSMDescr_t})::cusparseStatus_t
end

@checked function cusparseSpSM_destroyDescr(descr)
    initialize_context()
    @ccall libcusparse.cusparseSpSM_destroyDescr(descr::cusparseSpSMDescr_t)::cusparseStatus_t
end

@checked function cusparseSpSM_bufferSize(handle, opA, opB, alpha, matA, matB, matC,
                                          computeType, alg, spsmDescr, bufferSize)
    initialize_context()
    @ccall libcusparse.cusparseSpSM_bufferSize(handle::cusparseHandle_t,
                                               opA::cusparseOperation_t,
                                               opB::cusparseOperation_t, alpha::Ptr{Cvoid},
                                               matA::cusparseSpMatDescr_t,
                                               matB::cusparseDnMatDescr_t,
                                               matC::cusparseDnMatDescr_t,
                                               computeType::cudaDataType,
                                               alg::cusparseSpSMAlg_t,
                                               spsmDescr::cusparseSpSMDescr_t,
                                               bufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseSpSM_analysis(handle, opA, opB, alpha, matA, matB, matC,
                                        computeType, alg, spsmDescr, externalBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSpSM_analysis(handle::cusparseHandle_t,
                                             opA::cusparseOperation_t,
                                             opB::cusparseOperation_t, alpha::Ptr{Cvoid},
                                             matA::cusparseSpMatDescr_t,
                                             matB::cusparseDnMatDescr_t,
                                             matC::cusparseDnMatDescr_t,
                                             computeType::cudaDataType,
                                             alg::cusparseSpSMAlg_t,
                                             spsmDescr::cusparseSpSMDescr_t,
                                             externalBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSpSM_solve(handle, opA, opB, alpha, matA, matB, matC, computeType,
                                     alg, spsmDescr)
    initialize_context()
    @ccall libcusparse.cusparseSpSM_solve(handle::cusparseHandle_t,
                                          opA::cusparseOperation_t,
                                          opB::cusparseOperation_t, alpha::Ptr{Cvoid},
                                          matA::cusparseSpMatDescr_t,
                                          matB::cusparseDnMatDescr_t,
                                          matC::cusparseDnMatDescr_t,
                                          computeType::cudaDataType, alg::cusparseSpSMAlg_t,
                                          spsmDescr::cusparseSpSMDescr_t)::cusparseStatus_t
end

@cenum cusparseSpMMAlg_t::UInt32 begin
    CUSPARSE_MM_ALG_DEFAULT = 0
    CUSPARSE_COOMM_ALG1 = 1
    CUSPARSE_COOMM_ALG2 = 2
    CUSPARSE_COOMM_ALG3 = 3
    CUSPARSE_CSRMM_ALG1 = 4
    CUSPARSE_SPMM_ALG_DEFAULT = 0
    CUSPARSE_SPMM_COO_ALG1 = 1
    CUSPARSE_SPMM_COO_ALG2 = 2
    CUSPARSE_SPMM_COO_ALG3 = 3
    CUSPARSE_SPMM_COO_ALG4 = 5
    CUSPARSE_SPMM_CSR_ALG1 = 4
    CUSPARSE_SPMM_CSR_ALG2 = 6
    CUSPARSE_SPMM_CSR_ALG3 = 12
    CUSPARSE_SPMM_BLOCKED_ELL_ALG1 = 13
end

@checked function cusparseSpMM_bufferSize(handle, opA, opB, alpha, matA, matB, beta, matC,
                                          computeType, alg, bufferSize)
    initialize_context()
    @ccall libcusparse.cusparseSpMM_bufferSize(handle::cusparseHandle_t,
                                               opA::cusparseOperation_t,
                                               opB::cusparseOperation_t,
                                               alpha::PtrOrCuPtr{Cvoid},
                                               matA::cusparseSpMatDescr_t,
                                               matB::cusparseDnMatDescr_t,
                                               beta::PtrOrCuPtr{Cvoid},
                                               matC::cusparseDnMatDescr_t,
                                               computeType::cudaDataType,
                                               alg::cusparseSpMMAlg_t,
                                               bufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseSpMM_preprocess(handle, opA, opB, alpha, matA, matB, beta, matC,
                                          computeType, alg, externalBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSpMM_preprocess(handle::cusparseHandle_t,
                                               opA::cusparseOperation_t,
                                               opB::cusparseOperation_t,
                                               alpha::PtrOrCuPtr{Cvoid},
                                               matA::cusparseSpMatDescr_t,
                                               matB::cusparseDnMatDescr_t,
                                               beta::PtrOrCuPtr{Cvoid},
                                               matC::cusparseDnMatDescr_t,
                                               computeType::cudaDataType,
                                               alg::cusparseSpMMAlg_t,
                                               externalBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSpMM(handle, opA, opB, alpha, matA, matB, beta, matC, computeType,
                               alg, externalBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSpMM(handle::cusparseHandle_t, opA::cusparseOperation_t,
                                    opB::cusparseOperation_t, alpha::PtrOrCuPtr{Cvoid},
                                    matA::cusparseSpMatDescr_t, matB::cusparseDnMatDescr_t,
                                    beta::PtrOrCuPtr{Cvoid}, matC::cusparseDnMatDescr_t,
                                    computeType::cudaDataType, alg::cusparseSpMMAlg_t,
                                    externalBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@cenum cusparseSpGEMMAlg_t::UInt32 begin
    CUSPARSE_SPGEMM_DEFAULT = 0
    CUSPARSE_SPGEMM_CSR_ALG_DETERMINITIC = 1
    CUSPARSE_SPGEMM_CSR_ALG_NONDETERMINITIC = 2
end

mutable struct cusparseSpGEMMDescr end

const cusparseSpGEMMDescr_t = Ptr{cusparseSpGEMMDescr}

@checked function cusparseSpGEMM_createDescr(descr)
    initialize_context()
    @ccall libcusparse.cusparseSpGEMM_createDescr(descr::Ptr{cusparseSpGEMMDescr_t})::cusparseStatus_t
end

@checked function cusparseSpGEMM_destroyDescr(descr)
    initialize_context()
    @ccall libcusparse.cusparseSpGEMM_destroyDescr(descr::cusparseSpGEMMDescr_t)::cusparseStatus_t
end

@checked function cusparseSpGEMM_workEstimation(handle, opA, opB, alpha, matA, matB, beta,
                                                matC, computeType, alg, spgemmDescr,
                                                bufferSize1, externalBuffer1)
    initialize_context()
    @ccall libcusparse.cusparseSpGEMM_workEstimation(handle::cusparseHandle_t,
                                                     opA::cusparseOperation_t,
                                                     opB::cusparseOperation_t,
                                                     alpha::PtrOrCuPtr{Cvoid},
                                                     matA::cusparseSpMatDescr_t,
                                                     matB::cusparseSpMatDescr_t,
                                                     beta::PtrOrCuPtr{Cvoid},
                                                     matC::cusparseSpMatDescr_t,
                                                     computeType::cudaDataType,
                                                     alg::cusparseSpGEMMAlg_t,
                                                     spgemmDescr::cusparseSpGEMMDescr_t,
                                                     bufferSize1::Ptr{Csize_t},
                                                     externalBuffer1::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSpGEMM_compute(handle, opA, opB, alpha, matA, matB, beta, matC,
                                         computeType, alg, spgemmDescr, bufferSize2,
                                         externalBuffer2)
    initialize_context()
    @ccall libcusparse.cusparseSpGEMM_compute(handle::cusparseHandle_t,
                                              opA::cusparseOperation_t,
                                              opB::cusparseOperation_t,
                                              alpha::PtrOrCuPtr{Cvoid},
                                              matA::cusparseSpMatDescr_t,
                                              matB::cusparseSpMatDescr_t,
                                              beta::PtrOrCuPtr{Cvoid},
                                              matC::cusparseSpMatDescr_t,
                                              computeType::cudaDataType,
                                              alg::cusparseSpGEMMAlg_t,
                                              spgemmDescr::cusparseSpGEMMDescr_t,
                                              bufferSize2::Ptr{Csize_t},
                                              externalBuffer2::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSpGEMM_copy(handle, opA, opB, alpha, matA, matB, beta, matC,
                                      computeType, alg, spgemmDescr)
    initialize_context()
    @ccall libcusparse.cusparseSpGEMM_copy(handle::cusparseHandle_t,
                                           opA::cusparseOperation_t,
                                           opB::cusparseOperation_t,
                                           alpha::PtrOrCuPtr{Cvoid},
                                           matA::cusparseSpMatDescr_t,
                                           matB::cusparseSpMatDescr_t,
                                           beta::PtrOrCuPtr{Cvoid},
                                           matC::cusparseSpMatDescr_t,
                                           computeType::cudaDataType,
                                           alg::cusparseSpGEMMAlg_t,
                                           spgemmDescr::cusparseSpGEMMDescr_t)::cusparseStatus_t
end

@checked function cusparseSpGEMMreuse_workEstimation(handle, opA, opB, matA, matB, matC,
                                                     alg, spgemmDescr, bufferSize1,
                                                     externalBuffer1)
    initialize_context()
    @ccall libcusparse.cusparseSpGEMMreuse_workEstimation(handle::cusparseHandle_t,
                                                          opA::cusparseOperation_t,
                                                          opB::cusparseOperation_t,
                                                          matA::cusparseSpMatDescr_t,
                                                          matB::cusparseSpMatDescr_t,
                                                          matC::cusparseSpMatDescr_t,
                                                          alg::cusparseSpGEMMAlg_t,
                                                          spgemmDescr::cusparseSpGEMMDescr_t,
                                                          bufferSize1::Ptr{Csize_t},
                                                          externalBuffer1::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSpGEMMreuse_nnz(handle, opA, opB, matA, matB, matC, alg,
                                          spgemmDescr, bufferSize2, externalBuffer2,
                                          bufferSize3, externalBuffer3, bufferSize4,
                                          externalBuffer4)
    initialize_context()
    @ccall libcusparse.cusparseSpGEMMreuse_nnz(handle::cusparseHandle_t,
                                               opA::cusparseOperation_t,
                                               opB::cusparseOperation_t,
                                               matA::cusparseSpMatDescr_t,
                                               matB::cusparseSpMatDescr_t,
                                               matC::cusparseSpMatDescr_t,
                                               alg::cusparseSpGEMMAlg_t,
                                               spgemmDescr::cusparseSpGEMMDescr_t,
                                               bufferSize2::Ptr{Csize_t},
                                               externalBuffer2::CuPtr{Cvoid},
                                               bufferSize3::Ptr{Csize_t},
                                               externalBuffer3::CuPtr{Cvoid},
                                               bufferSize4::Ptr{Csize_t},
                                               externalBuffer4::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSpGEMMreuse_copy(handle, opA, opB, matA, matB, matC, alg,
                                           spgemmDescr, bufferSize5, externalBuffer5)
    initialize_context()
    @ccall libcusparse.cusparseSpGEMMreuse_copy(handle::cusparseHandle_t,
                                                opA::cusparseOperation_t,
                                                opB::cusparseOperation_t,
                                                matA::cusparseSpMatDescr_t,
                                                matB::cusparseSpMatDescr_t,
                                                matC::cusparseSpMatDescr_t,
                                                alg::cusparseSpGEMMAlg_t,
                                                spgemmDescr::cusparseSpGEMMDescr_t,
                                                bufferSize5::Ptr{Csize_t},
                                                externalBuffer5::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSpGEMMreuse_compute(handle, opA, opB, alpha, matA, matB, beta,
                                              matC, computeType, alg, spgemmDescr)
    initialize_context()
    @ccall libcusparse.cusparseSpGEMMreuse_compute(handle::cusparseHandle_t,
                                                   opA::cusparseOperation_t,
                                                   opB::cusparseOperation_t,
                                                   alpha::Ptr{Cvoid},
                                                   matA::cusparseSpMatDescr_t,
                                                   matB::cusparseSpMatDescr_t,
                                                   beta::Ptr{Cvoid},
                                                   matC::cusparseSpMatDescr_t,
                                                   computeType::cudaDataType,
                                                   alg::cusparseSpGEMMAlg_t,
                                                   spgemmDescr::cusparseSpGEMMDescr_t)::cusparseStatus_t
end

@checked function cusparseConstrainedGeMM(handle, opA, opB, alpha, matA, matB, beta, matC,
                                          computeType, externalBuffer)
    initialize_context()
    @ccall libcusparse.cusparseConstrainedGeMM(handle::cusparseHandle_t,
                                               opA::cusparseOperation_t,
                                               opB::cusparseOperation_t,
                                               alpha::PtrOrCuPtr{Cvoid},
                                               matA::cusparseDnMatDescr_t,
                                               matB::cusparseDnMatDescr_t,
                                               beta::PtrOrCuPtr{Cvoid},
                                               matC::cusparseSpMatDescr_t,
                                               computeType::cudaDataType,
                                               externalBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseConstrainedGeMM_bufferSize(handle, opA, opB, alpha, matA, matB,
                                                     beta, matC, computeType, bufferSize)
    initialize_context()
    @ccall libcusparse.cusparseConstrainedGeMM_bufferSize(handle::cusparseHandle_t,
                                                          opA::cusparseOperation_t,
                                                          opB::cusparseOperation_t,
                                                          alpha::Ptr{Cvoid},
                                                          matA::cusparseDnMatDescr_t,
                                                          matB::cusparseDnMatDescr_t,
                                                          beta::Ptr{Cvoid},
                                                          matC::cusparseSpMatDescr_t,
                                                          computeType::cudaDataType,
                                                          bufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@cenum cusparseSDDMMAlg_t::UInt32 begin
    CUSPARSE_SDDMM_ALG_DEFAULT = 0
end

@checked function cusparseSDDMM_bufferSize(handle, opA, opB, alpha, matA, matB, beta, matC,
                                           computeType, alg, bufferSize)
    initialize_context()
    @ccall libcusparse.cusparseSDDMM_bufferSize(handle::cusparseHandle_t,
                                                opA::cusparseOperation_t,
                                                opB::cusparseOperation_t,
                                                alpha::PtrOrCuPtr{Cvoid},
                                                matA::cusparseDnMatDescr_t,
                                                matB::cusparseDnMatDescr_t,
                                                beta::PtrOrCuPtr{Cvoid},
                                                matC::cusparseSpMatDescr_t,
                                                computeType::cudaDataType,
                                                alg::cusparseSDDMMAlg_t,
                                                bufferSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseSDDMM_preprocess(handle, opA, opB, alpha, matA, matB, beta, matC,
                                           computeType, alg, externalBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSDDMM_preprocess(handle::cusparseHandle_t,
                                                opA::cusparseOperation_t,
                                                opB::cusparseOperation_t,
                                                alpha::PtrOrCuPtr{Cvoid},
                                                matA::cusparseDnMatDescr_t,
                                                matB::cusparseDnMatDescr_t,
                                                beta::PtrOrCuPtr{Cvoid},
                                                matC::cusparseSpMatDescr_t,
                                                computeType::cudaDataType,
                                                alg::cusparseSDDMMAlg_t,
                                                externalBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSDDMM(handle, opA, opB, alpha, matA, matB, beta, matC,
                                computeType, alg, externalBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSDDMM(handle::cusparseHandle_t, opA::cusparseOperation_t,
                                     opB::cusparseOperation_t, alpha::PtrOrCuPtr{Cvoid},
                                     matA::cusparseDnMatDescr_t, matB::cusparseDnMatDescr_t,
                                     beta::PtrOrCuPtr{Cvoid}, matC::cusparseSpMatDescr_t,
                                     computeType::cudaDataType, alg::cusparseSDDMMAlg_t,
                                     externalBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

mutable struct cusparseSpMMOpPlan end

const cusparseSpMMOpPlan_t = Ptr{cusparseSpMMOpPlan}

@cenum cusparseSpMMOpAlg_t::UInt32 begin
    CUSPARSE_SPMM_OP_ALG_DEFAULT = 0
end

@checked function cusparseSpMMOp_createPlan(handle, plan, opA, opB, matA, matB, matC,
                                            computeType, alg, addOperationNvvmBuffer,
                                            addOperationBufferSize, mulOperationNvvmBuffer,
                                            mulOperationBufferSize, epilogueNvvmBuffer,
                                            epilogueBufferSize, SpMMWorkspaceSize)
    initialize_context()
    @ccall libcusparse.cusparseSpMMOp_createPlan(handle::cusparseHandle_t,
                                                 plan::Ptr{cusparseSpMMOpPlan_t},
                                                 opA::cusparseOperation_t,
                                                 opB::cusparseOperation_t,
                                                 matA::cusparseSpMatDescr_t,
                                                 matB::cusparseDnMatDescr_t,
                                                 matC::cusparseDnMatDescr_t,
                                                 computeType::cudaDataType,
                                                 alg::cusparseSpMMOpAlg_t,
                                                 addOperationNvvmBuffer::Ptr{Cvoid},
                                                 addOperationBufferSize::Csize_t,
                                                 mulOperationNvvmBuffer::Ptr{Cvoid},
                                                 mulOperationBufferSize::Csize_t,
                                                 epilogueNvvmBuffer::Ptr{Cvoid},
                                                 epilogueBufferSize::Csize_t,
                                                 SpMMWorkspaceSize::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseSpMMOp(plan, externalBuffer)
    initialize_context()
    @ccall libcusparse.cusparseSpMMOp(plan::cusparseSpMMOpPlan_t,
                                      externalBuffer::CuPtr{Cvoid})::cusparseStatus_t
end

@checked function cusparseSpMMOp_destroyPlan(plan)
    initialize_context()
    @ccall libcusparse.cusparseSpMMOp_destroyPlan(plan::cusparseSpMMOpPlan_t)::cusparseStatus_t
end

# Skipping MacroDefinition: CUSPARSE_DEPRECATED ( new_func ) __attribute__ ( ( deprecated ( "please use " # new_func " instead" ) ) )

# Float16 functionality is only enabled when using C++ (defining __cplusplus breaks things)

@checked function cusparseHpruneDense2csr_bufferSizeExt(handle, m, n, A, lda, threshold,
                                                        descrC, csrSortedValC,
                                                        csrSortedRowPtrC, csrSortedColIndC,
                                                        pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseHpruneDense2csr_bufferSizeExt(handle::cusparseHandle_t,
                                                             m::Cint, n::Cint,
                                                             A::Ptr{Float16}, lda::Cint,
                                                             threshold::Ptr{Float16},
                                                             descrC::cusparseMatDescr_t,
                                                             csrSortedValC::Ptr{Float16},
                                                             csrSortedRowPtrC::Ptr{Cint},
                                                             csrSortedColIndC::Ptr{Cint},
                                                             pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseHpruneDense2csrNnz(handle, m, n, A, lda, threshold, descrC,
                                             csrRowPtrC, nnzTotalDevHostPtr, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseHpruneDense2csrNnz(handle::cusparseHandle_t, m::Cint,
                                                  n::Cint, A::Ptr{Float16}, lda::Cint,
                                                  threshold::Ptr{Float16},
                                                  descrC::cusparseMatDescr_t,
                                                  csrRowPtrC::Ptr{Cint},
                                                  nnzTotalDevHostPtr::Ptr{Cint},
                                                  pBuffer::Ptr{Cvoid})::cusparseStatus_t
end

@checked function cusparseHpruneDense2csr(handle, m, n, A, lda, threshold, descrC,
                                          csrSortedValC, csrSortedRowPtrC, csrSortedColIndC,
                                          pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseHpruneDense2csr(handle::cusparseHandle_t, m::Cint, n::Cint,
                                               A::Ptr{Float16}, lda::Cint,
                                               threshold::Ptr{Float16},
                                               descrC::cusparseMatDescr_t,
                                               csrSortedValC::Ptr{Float16},
                                               csrSortedRowPtrC::Ptr{Cint},
                                               csrSortedColIndC::Ptr{Cint},
                                               pBuffer::Ptr{Cvoid})::cusparseStatus_t
end

@checked function cusparseHpruneCsr2csr_bufferSizeExt(handle, m, n, nnzA, descrA,
                                                      csrSortedValA, csrSortedRowPtrA,
                                                      csrSortedColIndA, threshold, descrC,
                                                      csrSortedValC, csrSortedRowPtrC,
                                                      csrSortedColIndC, pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseHpruneCsr2csr_bufferSizeExt(handle::cusparseHandle_t,
                                                           m::Cint, n::Cint, nnzA::Cint,
                                                           descrA::cusparseMatDescr_t,
                                                           csrSortedValA::Ptr{Float16},
                                                           csrSortedRowPtrA::Ptr{Cint},
                                                           csrSortedColIndA::Ptr{Cint},
                                                           threshold::Ptr{Float16},
                                                           descrC::cusparseMatDescr_t,
                                                           csrSortedValC::Ptr{Float16},
                                                           csrSortedRowPtrC::Ptr{Cint},
                                                           csrSortedColIndC::Ptr{Cint},
                                                           pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseHpruneCsr2csrNnz(handle, m, n, nnzA, descrA, csrSortedValA,
                                           csrSortedRowPtrA, csrSortedColIndA, threshold,
                                           descrC, csrSortedRowPtrC, nnzTotalDevHostPtr,
                                           pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseHpruneCsr2csrNnz(handle::cusparseHandle_t, m::Cint, n::Cint,
                                                nnzA::Cint, descrA::cusparseMatDescr_t,
                                                csrSortedValA::Ptr{Float16},
                                                csrSortedRowPtrA::Ptr{Cint},
                                                csrSortedColIndA::Ptr{Cint},
                                                threshold::Ptr{Float16},
                                                descrC::cusparseMatDescr_t,
                                                csrSortedRowPtrC::Ptr{Cint},
                                                nnzTotalDevHostPtr::Ptr{Cint},
                                                pBuffer::Ptr{Cvoid})::cusparseStatus_t
end

@checked function cusparseHpruneCsr2csr(handle, m, n, nnzA, descrA, csrSortedValA,
                                        csrSortedRowPtrA, csrSortedColIndA, threshold,
                                        descrC, csrSortedValC, csrSortedRowPtrC,
                                        csrSortedColIndC, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseHpruneCsr2csr(handle::cusparseHandle_t, m::Cint, n::Cint,
                                             nnzA::Cint, descrA::cusparseMatDescr_t,
                                             csrSortedValA::Ptr{Float16},
                                             csrSortedRowPtrA::Ptr{Cint},
                                             csrSortedColIndA::Ptr{Cint},
                                             threshold::Ptr{Float16},
                                             descrC::cusparseMatDescr_t,
                                             csrSortedValC::Ptr{Float16},
                                             csrSortedRowPtrC::Ptr{Cint},
                                             csrSortedColIndC::Ptr{Cint},
                                             pBuffer::Ptr{Cvoid})::cusparseStatus_t
end

@checked function cusparseHpruneDense2csrByPercentage_bufferSizeExt(handle, m, n, A, lda,
                                                                    percentage, descrC,
                                                                    csrSortedValC,
                                                                    csrSortedRowPtrC,
                                                                    csrSortedColIndC, info,
                                                                    pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseHpruneDense2csrByPercentage_bufferSizeExt(handle::cusparseHandle_t,
                                                                         m::Cint, n::Cint,
                                                                         A::Ptr{Float16},
                                                                         lda::Cint,
                                                                         percentage::Cfloat,
                                                                         descrC::cusparseMatDescr_t,
                                                                         csrSortedValC::Ptr{Float16},
                                                                         csrSortedRowPtrC::Ptr{Cint},
                                                                         csrSortedColIndC::Ptr{Cint},
                                                                         info::pruneInfo_t,
                                                                         pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseHpruneDense2csrNnzByPercentage(handle, m, n, A, lda, percentage,
                                                         descrC, csrRowPtrC,
                                                         nnzTotalDevHostPtr, info, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseHpruneDense2csrNnzByPercentage(handle::cusparseHandle_t,
                                                              m::Cint, n::Cint,
                                                              A::Ptr{Float16}, lda::Cint,
                                                              percentage::Cfloat,
                                                              descrC::cusparseMatDescr_t,
                                                              csrRowPtrC::Ptr{Cint},
                                                              nnzTotalDevHostPtr::Ptr{Cint},
                                                              info::pruneInfo_t,
                                                              pBuffer::Ptr{Cvoid})::cusparseStatus_t
end

@checked function cusparseHpruneDense2csrByPercentage(handle, m, n, A, lda, percentage,
                                                      descrC, csrSortedValC,
                                                      csrSortedRowPtrC, csrSortedColIndC,
                                                      info, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseHpruneDense2csrByPercentage(handle::cusparseHandle_t,
                                                           m::Cint, n::Cint,
                                                           A::Ptr{Float16}, lda::Cint,
                                                           percentage::Cfloat,
                                                           descrC::cusparseMatDescr_t,
                                                           csrSortedValC::Ptr{Float16},
                                                           csrSortedRowPtrC::Ptr{Cint},
                                                           csrSortedColIndC::Ptr{Cint},
                                                           info::pruneInfo_t,
                                                           pBuffer::Ptr{Cvoid})::cusparseStatus_t
end

@checked function cusparseHpruneCsr2csrByPercentage_bufferSizeExt(handle, m, n, nnzA,
                                                                  descrA, csrSortedValA,
                                                                  csrSortedRowPtrA,
                                                                  csrSortedColIndA,
                                                                  percentage, descrC,
                                                                  csrSortedValC,
                                                                  csrSortedRowPtrC,
                                                                  csrSortedColIndC, info,
                                                                  pBufferSizeInBytes)
    initialize_context()
    @ccall libcusparse.cusparseHpruneCsr2csrByPercentage_bufferSizeExt(handle::cusparseHandle_t,
                                                                       m::Cint, n::Cint,
                                                                       nnzA::Cint,
                                                                       descrA::cusparseMatDescr_t,
                                                                       csrSortedValA::Ptr{Float16},
                                                                       csrSortedRowPtrA::Ptr{Cint},
                                                                       csrSortedColIndA::Ptr{Cint},
                                                                       percentage::Cfloat,
                                                                       descrC::cusparseMatDescr_t,
                                                                       csrSortedValC::Ptr{Float16},
                                                                       csrSortedRowPtrC::Ptr{Cint},
                                                                       csrSortedColIndC::Ptr{Cint},
                                                                       info::pruneInfo_t,
                                                                       pBufferSizeInBytes::Ptr{Csize_t})::cusparseStatus_t
end

@checked function cusparseHpruneCsr2csrNnzByPercentage(handle, m, n, nnzA, descrA,
                                                       csrSortedValA, csrSortedRowPtrA,
                                                       csrSortedColIndA, percentage, descrC,
                                                       csrSortedRowPtrC, nnzTotalDevHostPtr,
                                                       info, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseHpruneCsr2csrNnzByPercentage(handle::cusparseHandle_t,
                                                            m::Cint, n::Cint, nnzA::Cint,
                                                            descrA::cusparseMatDescr_t,
                                                            csrSortedValA::Ptr{Float16},
                                                            csrSortedRowPtrA::Ptr{Cint},
                                                            csrSortedColIndA::Ptr{Cint},
                                                            percentage::Cfloat,
                                                            descrC::cusparseMatDescr_t,
                                                            csrSortedRowPtrC::Ptr{Cint},
                                                            nnzTotalDevHostPtr::Ptr{Cint},
                                                            info::pruneInfo_t,
                                                            pBuffer::Ptr{Cvoid})::cusparseStatus_t
end

@checked function cusparseHpruneCsr2csrByPercentage(handle, m, n, nnzA, descrA,
                                                    csrSortedValA, csrSortedRowPtrA,
                                                    csrSortedColIndA, percentage, descrC,
                                                    csrSortedValC, csrSortedRowPtrC,
                                                    csrSortedColIndC, info, pBuffer)
    initialize_context()
    @ccall libcusparse.cusparseHpruneCsr2csrByPercentage(handle::cusparseHandle_t, m::Cint,
                                                         n::Cint, nnzA::Cint,
                                                         descrA::cusparseMatDescr_t,
                                                         csrSortedValA::Ptr{Float16},
                                                         csrSortedRowPtrA::Ptr{Cint},
                                                         csrSortedColIndA::Ptr{Cint},
                                                         percentage::Cfloat,
                                                         descrC::cusparseMatDescr_t,
                                                         csrSortedValC::Ptr{Float16},
                                                         csrSortedRowPtrC::Ptr{Cint},
                                                         csrSortedColIndC::Ptr{Cint},
                                                         info::pruneInfo_t,
                                                         pBuffer::Ptr{Cvoid})::cusparseStatus_t
end
