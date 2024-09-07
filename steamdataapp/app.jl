using SQLite
using DataFrames
using GenieFramework

@genietools
const db = SQLite.DB(joinpath("dbase", "data.db")) #connect to sqlite
const table_options = DataTableOptions(columns = Column(["ID", "Score", "Title", "Total", "Release", "LaunchPrice", "Tags", "SteamPage"]))


function classify_scores(score)
  if score >= 90
      return "Excellent"
  elseif score >= 80
      return "Good"
  elseif score >= 70
      return "Average"
  else
      return "Below Average"
  end
end

@app begin
  @in year = RangeData(1970:2023) # user input range data slider
  @in score = RangeData(0:96)
  @out datatable = DataTable()
  @out piechart = PlotData(; values = [], labels = [], plot = "pie")
  @out dataplot = PlotData[] 
  @out datatablepagination = DataTablePagination(rows_per_page=150) #150 rows per table page
  @out data_count = 0
  @out excellent_titles = []   
  
  @onchange year, score begin     #if year or score values changes
    query = "SELECT * FROM Steam WHERE Year >= $(year.range[1]) AND Year <= $(year.range[end]) AND Score >= $(score.range[1]) AND Score <= $(score.range[end])" #request information from the database where it'll select all columns with year and score values in between
    result = DBInterface.execute(db, query) |> DataFrame #store the result of the query in a dataframe
    datatable = DataTable(result, table_options) #display the result in a datatable and get the column names from table_options

    result.classified_score = classify_scores.(result.Score)
    score_counts = combine(groupby(result, :classified_score), :Score => length)
    piechart = PlotData(
        values = score_counts.Score_length ,
        labels = score_counts.classified_score,
        plot = "pie",
    )
    excellent_titles = unique(result[result.classified_score .== "Excellent", :Title])
    data_count = size(result ,1 )
    dataplot = [PlotData(
    x = result.Year,
    y = result.Score,
    text = coalesce.(result.Title, ""),
    mode = "markers",
    marker = Dict("color" => result.Score, "colorscale" => "Viridis", "line" => Dict("color" => "black", "width" => 0.5))
)]
 
  end
end

@page("/", "app.jl.html")

