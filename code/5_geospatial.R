list.of.packages <- c("sp","rgdal","leaflet","data.table","ggplot2","scales")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

# There are two important ways of importing geospatial data into R, and two useful ways of visualizing it

# The first way of importing is if you have a SHP file. These generally come in a folder with multiple
# files (shp, xml, dbf, etc.). It's important to make sure you keep them together.
# Make sure you edit your WD before attempting to load this file.
setwd("~/git/di_r_reference")
ug = readOGR("data/ug_shp/uganda.shp")

# You can view the data attached to a Shapefile by accessing the data attribute of the 
# large SpatialPolygonsDataFrame
View(ug@data)
# And you can preview the shapes with a simple plot
plot(ug)

# The second way of importing data is through a CSV that contains longitude and latitude.
# You just read the CSV as normal, and then you tell R which columns contain the coordinates
cities = read.csv("data/cities.csv")
coordinates(cities)=~long+lat
points(cities)

# That's all well and good, but what use is a black and white outline?
# Let's first make a static map using ggplot

# Define some DI colours
reds = c("#FBD7CB","#F6B2A7","#F28E83","#ED695E","#E8443A")

# Load some data
pov = read.csv("data/pov.csv",na.strings="",as.is=T)

# In order to graph the shapefile with ggplot, we need to turn the polygons into a mesh of points
# This is accomplished with a function called `fortify`
ug.f = fortify(ug,region="name")
setnames(ug.f,"id","name")

# And then we can merge our poverty data in
ug.f = merge(ug.f,pov,by="name",all.x=T)

# Set our stops for the legend
palbins = c(30,50,70,90,97)
names(palbins)=c("30 %","50 %","70 %","90 %","97 %")

# And draw a map using geom_polygon
ggplot(ug.f)+
  geom_polygon( aes(x=long,y=lat,group=group,fill=poverty,color="#eeeeee",size=0.21))+
  coord_fixed(1) + # 1 to 1 ratio for longitude to latitude
  # or coord_cartesian() +
  scale_fill_gradientn(
    na.value="#d0cccf",
    guide="legend",
    breaks=palbins,
    colors=reds,
    values=rescale(palbins)
  ) +
  scale_color_identity()+
  scale_size_identity()+
  expand_limits(x=ug.f$long,y=ug.f$lat)+
  theme_classic()+
  theme(axis.line = element_blank(),axis.text=element_blank(),axis.ticks = element_blank())+
  guides(fill=guide_legend(title=""))+
  labs(x="",y="")

# Save it as an SVG in the output folder
ggsave("output/ug_pov.svg")

# Now, I can show you how to make an interactive map using Leaflet
ug = merge(ug,pov,by="name")

# Pick out the centers of the polygons for labels
centroids = getSpPPolygonsLabptSlots(ug)
label.df = data.frame(long=centroids[,1],lat=centroids[,2],label=ug@data$name,percent=ug@data$poverty)
label.df = subset(label.df,percent>80)
coordinates(label.df)=~long+lat

# Let the palette
pal <- colorBin(
  palette = "YlOrRd",
  domain = ug@data[,"poverty"],
  na.color="#d0cccf",
  bins = c(0,20,40,60,80,100)
)

# You may need to highlight all lines at once to get this to run
leaflet(data=ug) %>%
  setView(33, 1, zoom=6) %>% 
  addPolygons(color = pal(ug@data[,"poverty"])
              ,fillOpacity = 1
              ,stroke=F
              ,smoothFactor=0.2
              ,popup=paste0(
                "<b>District name</b>: ",ug@data$name,"<br/>",
                "<b>Share in poverty (2014): </b>$",round(ug@data$poverty),"<br/>"
              )) %>%
  addPolylines(
    color="#eeeeee",
    weight=0.5,
    opacity=1,
    smoothFactor=0.2) %>%
  addLabelOnlyMarkers(
    data=label.df,
    label=~label,
    labelOptions = labelOptions(
      noHide=T,
      textOnly=T,
      direction="right",
      style= list(
        "font-family"="serif"
        ,"text-shadow"="-1px 0 white, 0 1px white, 1px 0 white, 0 -1px white" ))) %>%
  addMarkers(
    data=cities
    ,popup=paste0(
      "<b>City name: </b>",cities@data$city,"<br/>",
      "<b>District: </b>",cities@data$district,"<br/>",
      "<b>Total FDI, 2012-2016 (US$ millions): </b>$",round(cities@data$fdi),"<br/>"
    )
    ) %>%
  addLegend(
    "bottomright"
    , pal=pal
    , values = ug@data[,"poverty"]
    , opacity = 1
    , title="Share in poverty (2014)"
    ,labFormat = labelFormat(suffix="%")
    ,na.label = "0/no data"
  )

# And then you can use the "Export" dropdown in the viewer in R studio to export an HTML website.

# Lastly, one important geospatial transformation is the `point-in-polygon` operator
# Where you need to find which polygon a point belongs to.
# Let's say we forgot which district each city was in
cities$district = as.character(cities$district)
cities_copy = cities
cities_copy$district = NULL

# As long as our points and polygons are in the same spatial reference frame, we can calculate
# which polygon each point belongs to
proj4string(cities_copy) = proj4string(ug)
over_dat = over(cities_copy,ug)
cities_copy$district = over_dat$name
# Check to see whether our calculated names match the old ones
cities_copy$district == cities$district
