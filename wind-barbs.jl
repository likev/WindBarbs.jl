module WindBarbs

export wind_path, wind_rotation, scatter_wind, scatter_wind!, scatter_wind2, scatter_wind2!

using CairoMakie

function wind_path(value)
    value > 1000 && return

    height = 32
    s = 8
    w = 18

    ax = 0
    ay = height

    δ = w * tan(5 * pi / 180)

    pathvector::Vector{Any} = [MoveTo(0, 0)]

    # println(typeof(pathvector))

    push!(pathvector, LineTo(ax, ay))

    rest = value + 1
    n20 = floor(Int, rest / 20)

    # println(n20);

    for i in 1:n20
        push!(pathvector, LineTo(ax + w, ay - δ))
        ay -= s
        push!(pathvector, LineTo(ax, ay))
    end

    s = 6
    rest -= n20 * 20
    n4 = floor(Int, rest / 4)

    for i in 1:n4
        push!(pathvector, LineTo(ax + w, ay + 2δ))
        push!(pathvector, LineTo(ax, ay)) #fix fill
        ay -= s
        push!(pathvector, MoveTo(ax, ay))
    end

    rest -= n4 * 4

    if (rest >= 2)
        push!(pathvector, LineTo(ax + w / 2, ay + δ))
        push!(pathvector, LineTo(ax, ay)) #fix fill
    end

    # stroke()

    pathvector
end


function wind_rotation(u, v)
    u == 0 ? pi : pi + atan(v / u) - sign(u) * pi / 2
end

function scatter_wind2(;
    xs::T, ys::T,
    us::M, vs::M,
    size=0.3, filename::String=nothing
) where {
    T<:Union{AbstractRange,Vector},
    M<:Matrix
}
    f = Figure()
    ax = Axis(f[1, 1])
    limits!(ax, 0, 3, 0, 3)

    scatter_wind2!(ax; xs, ys, us, vs, size)

    isnothing(filename) ? nothing : save(filename, f)
    f
end

function scatter_wind2!(ax;
    xs::T, ys::T,
    us::M, vs::M,
    size=0.3
) where {
    T<:Union{AbstractRange,Vector},
    M<:Matrix
}

    xlength = length(xs)
    ylength = length(ys)

    for x in 1:xlength
        # println(typeof(fill(xs[x], ylength)), typeof(collect(ys)), typeof(us[x, :]), typeof(vs[x, :]))
        scatter_wind_uv!(ax; xs=fill(xs[x], ylength), ys=collect(ys), us=us[x, :], vs=vs[x, :], size=size)
    end

    ax
end

function scatter_wind_uv!(ax;
    xs::T, ys::T,
    us::V, vs::V,
    size=0.3
) where {
    T<:Union{AbstractRange,Vector},
    V<:Vector
}
    windv = @. sqrt(us^2 + vs^2)
    rotations = @. wind_rotation(us, vs)

    # println((xs, ys, windv))

    wind_markers = @. windv |> wind_path |> BezierPath

    scatter!(ax, xs, ys,
        marker=wind_markers,
        markersize=size,
        rotations=rotations,
        #color=:transparent, 
        strokecolor=:black, strokewidth=1
    )

    ax
end


function scatter_wind_vd!(ax;
    xs::T, ys::T,
    vals::V, dirs::V,
    size::Real=0.3
) where {
    T<:Union{AbstractRange,Vector,Observable{Vector{Real}}},
    V<:Union{Vector,Observable{Vector{Real}}}
}
    windv = vals
    rotations = begin
        isa(dirs, Observable) ?
        @lift(2pi .- $dirs * pi ./ 180) :
        @. 2pi - dirs * pi / 180
    end

    # println((xs, ys, windv))

    wind_markers = begin
        isa(windv, Observable) ?
        @lift($windv .|> wind_path .|> BezierPath) :
        @. windv |> wind_path |> BezierPath
    end

    scatter!(ax, xs, ys,
        marker=wind_markers,
        markersize=size,
        rotations=rotations,
        #color=:transparent, 
        strokecolor=:black, strokewidth=1
    )

    ax
end

function scatter_wind!(ax;
    xs::T, ys::T,
    us::V1=nothing, vs::V1=nothing,
    vals::V2=nothing, dirs::V2=nothing,
    size=0.3, filename::String=nothing
) where {
    T<:Union{AbstractRange,Vector,Observable{Vector{Real}}},
    V1<:Union{Nothing,Vector,Observable{Vector{Real}}},
    V2<:Union{Nothing,Vector,Observable{Vector{Real}}}
}
    if us !== nothing && vs !== nothing
        scatter_wind_uv!(ax; xs, ys, us, vs, size)
    elseif vals !== nothing && dirs !== nothing
        scatter_wind_vd!(ax; xs, ys, vals, dirs, size)
    else
        println("Invalid arguments")
    end
end

function scatter_wind(;
    xs::T, ys::T,
    us::V1=nothing, vs::V1=nothing,
    vals::V2=nothing, dirs::V2=nothing,
    size=0.3, filename::String=nothing
) where {
    T<:Union{AbstractRange,Vector},
    V1<:Union{Nothing,Vector},
    V2<:Union{Nothing,Vector}
}
    f = Figure()
    ax = Axis(f[1, 1])
    limits!(ax, 0, 3, 0, 3)

    scatter_wind!(ax; xs, ys, us, vs, vals, dirs, size=0.3, filename)

    isnothing(filename) ? nothing : save(filename, f)
    f
end


function test()
    println(wind_path(30))
    println(wind_path(20))
    println(wind_path(18))
    println(wind_path(15))
    println(wind_path(4))

    windpath = BezierPath(wind_path(30))

    p = scatter(1:5,
        marker=windpath,
        markersize=range(1, 2, length=5),
        rotations=range(0, 2pi, length=6)[1:end-1],

        # color=:transparent, 
        strokecolor=:black, strokewidth=1
    )

    save("scatter-path.png", p)
    scatter_wind2(xs=1:2, ys=1:2, us=[10 10; -10 -10], vs=[10 -10; -10 10], filename="scatter-path2.png")
    scatter_wind(xs=[1, 1, 2, 2], ys=[1, 2, 1, 2], us=[10, 10, -10, -10], vs=[10, -10, -10, 10], filename="scatter-path3.png")
end

end