
using PlotlyJS

function map()
    geo = attr(scope="usa",
        projection_type="albers usa",
        showland=true,
        landcolor="rgb(217, 217, 217)",
        subunitwidth=1,
        countrywidth=1,
        subunitcolor="rgb(255,255,255)",
        countrycolor="rgb(255,255,255)")

    trace = scattergeo(;locationmode="USA-states",lat=[34,41],lon=[-104,-105])
    layout=Layout(;title="GNSS Interference, Denver Area, January 2022",showlegend=false,geo=geo)
    plot(trace, layout)
end
map()


