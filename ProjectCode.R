#Libraries
library(tidyverse)
library(rnpn)
library(dplyr)
library(lubridate)
library(leaflet)
library(readxl)
library(sf)
library(spData)
library(ggmap)
library(leafpop)
library(knitr)
library(broom)
library(data.table)
library(DT)
library(widgetframe)
library(kableExtra)
#npn_groups() %>%
#filter(grepl("Buffalo",network_name)) <- Identifies network ID

#Getting and defining data
d=npn_download_status_data("Testing",
                           years=c('2019'),
                           additional_fields=list("Plant_Nickname",
                                                  "ObservedBy_Person_ID"), 
                           network_ids=c(891))

#Cleaning the intensity column
d_filtered <- d %>%
  rename("a"="intensity_value") %>% 
  mutate(
    date = as.Date(observation_date),
    month = month(date),
    tag = as.numeric(substr(plant_nickname,1,3)),
    intensity=case_when(
      a == "Less than 5%" ~ 2.5,
      a == "Less than 25%" ~ 20,
      a == "5-24%" ~ 14.5,
      a == "25-49%" ~ 37,
      a == "50-74%" ~ 62,
      a == "75-94%" ~ 84.5,
      a == "95% or more"  ~ 97.5,
      a == "Less than 3"  ~ 2,  
      a == "3 to 10" ~ 6.5,
      a == "11 to 100" ~ 50,
      a == "101 to 1,000" ~ 500,
      a == "1,001 to 10,000" ~ 5000,
      a == "Little" ~ 5,
      a == "Some" ~ 3,  
      TRUE ~ as.numeric(NA)
    ))%>%
  filter(phenophase_description%in%c("Leaves","Colored leaves"))

#looking at the structure
str(d)
glimpse(d)
unique(d$species)

d_filtered <- d_filtered %>%
  mutate(leaf_drop = case_when(
    intensity < 50 ~ "Dropped",
    intensity >= 50 ~ "Not Dropped"
  ))

d_filtered %>%
  group_by(month) %>%
  count(leaf_drop) %>%
  ggplot(aes(x = month, y = n, color = leaf_drop)) + geom_line()


d_filtered %>%
  filter(month >= 9, !is.na(leaf_drop)) %>%
  ggplot(aes(x = month, fill = leaf_drop)) +
  geom_bar() +
  facet_wrap(~ common_name)

d_filtered %>%
  filter(phenophase_description=="Leaves",
         between(month,9,11)) %>% 
  group_by(observedby_person_id, month)%>%
  summarize(total_obs=n()) %>% 
  #left_join(select(ungroup(d_obs),ubit,percent),by="ubit") %>% 
  #  ggplot(aes(x=week,y=reorder(ubit,percent),fill=total_obs)) +
  ggplot(aes(x=as.factor(month),y=as.character(observedby_person_id),fill=total_obs)) +
  #facet_wrap(~group,scales="free_y")+
  geom_tile()+
  scale_fill_viridis_c()+
  ylab("Observation ID") %>%
 

d_filtered %>%
  group_by(common_name) %>%
  count()
#Data Exploration
table <- prop.table(table(d$common_name)) * 100
table %>%
  kable(col.names = c("Common Name","Percentage of Observations"),
        digits = 2) %>%
  kable_styling(full_width = FALSE, fixed_thead = TRUE) %>%
  scroll_box(width = "500px", height = "200px", fixed_thead = TRUE)

d_filtered %>%
  group_by(common_name, month) %>%
  filter(month >= 9) %>%
  summarize(var_intensity = var(intensity,na.rm = TRUE),
            mean_intensity = mean(intensity, na.rm = TRUE)) %>%
  ggplot(aes(x = month, y = mean_intensity)) +
  geom_line() + facet_wrap(~ common_name)

#Variance and mean intensity per tree id
d_filtered %>%
  group_by(common_name, month) %>%
  summarize(var_intensity = var(intensity,na.rm = TRUE),
            mean_intensity = mean(intensity, na.rm = TRUE)) %>%
  filter(var_intensity != 0) %>%
  kable(digits = 2,
        col.names = c("Name","Month","Intensity Variance","Intensity Average")) %>%
  kable_styling() %>%
  scroll_box(width = "500px", height = "200px")

d_filtered %>%
  group_by(tag,observedby_person_id) %>%
  summarize(var_intensity = var(intensity,na.rm = TRUE)) %>%
  filter(var_intensity != 0) %>%
  kable(digits = 2,
        col.names = c("Tag ID","Person ID","Intensity Variance")) %>%
  kable_styling() %>%
  scroll_box(width = "500px", height = "200px")

d_filtered %>%
  group_by(observedby_person_id) %>%
  count() %>%
  arrange(desc(n)) %>%
  kable(digits = 2,
        col.names = c("Person ID","Count of Observations")) %>%
  kable_styling() %>%
  scroll_box(width = "500px", height = "200px")



d_filtered %>%
  group_by(common_name,month) %>%
  summarize(var_intensity = var(intensity,na.rm = TRUE),
            mean_intensity = mean(intensity, na.rm = TRUE)) %>%
  ggplot(aes(x = month, y = var_intensity)) +
  geom_line() + facet_wrap(~ common_name)

d_filtered %>%
  group_by(common_name,month) %>%
  ggplot(aes(x = month, fill = leaf_drop)) +
  geom_bar(position = "fill") + facet_wrap(~ common_name)

d_filtered %>%
  group_by(common_name,month) %>%
  summarize(var_intensity = var(intensity,na.rm = TRUE),
            mean_intensity = mean(intensity, na.rm = TRUE)) %>%
  ggplot(aes(x = 1, y = var_intensity)) +
  geom_boxplot() +
  facet_wrap(~ common_name)

d_filtered %>%
  group_by(species) %>%
  count(phenophase_description)

ggplot(d_filtered, aes(x = species, fill = species)) +
  geom_bar(position = "dodge") +
  ylab("Count of Observations") +
  xlab("Species")

ggplot(d_filtered, aes(x = month, fill = species)) +
  geom_bar(position = "fill") +
  ylab("Count of Observations") +
  xlab("Species")

ggplot(d, aes(x = phenophase_description, fill = species)) +
  geom_bar()

d %>%
  group_by(day_of_year) %>%
  count()

d_filtered %>%
  group_by(species, month) %>%
  summarise(variance = var(intensity))
#This code was generated by Professor Wilson
plot <- d_filtered %>% 
  ggplot(aes(x=date,
             y=intensity,
             group=phenophase_description,
             col=phenophase_description))+
  geom_point()+
  facet_wrap(~common_name)+
  ylim(0,100)+
  geom_smooth(span=3)

d_filtered %>%
  filter(a != -9999) %>%
  ggplot(aes(x = date,
             fill = a)) +
  geom_bar(alpha = 0.8) + facet_wrap(~ common_name)

d_filtered %>%
  ggplot(aes(x = 1, y = intensity)) +
  geom_boxplot() +
  facet_wrap(~ common_name)

################

trees <- read_csv("trees.csv")
str(trees)

##Leaflet map of ellicott complex!
leaflet() %>%
  addTiles() %>%
  addCircleMarkers(data = trees, ~lon, ~lat, 
                   popup = paste("Tag:", trees$tag, "<br>",
                                 "Species:", trees$species, "<br>"),
                   fill = TRUE,
                   fillColor  = ~ common_name)

leaflet(trees) %>%
  addTiles() %>%
  addMarkers(~lon, ~lat,
             icon = icons,
             label = paste("Tag:", trees$tag, "|",
                           "Species:", trees$common_name))

leaflet(trees) %>% addTiles() %>%
  addAwesomeMarkers(~lon, ~lat,
                    icon = icons,
                    label = paste("Tag:", trees$tag, "|",
                                  "Species:", trees$common_name))

##RSTUDIO/leaflet/markers, popups and labels
##Add time dimension somehow
#Create new column with the color

unique(trees$common_name)

trees <- trees %>% 
  mutate(color = case_when (
    common_name == "Red Oak" ~ "red",
    common_name == "Black Oak" ~ "black",
    common_name == "Silver Maple" ~ "darkblue",
    common_name == "Red Maple" ~ "orange",
    common_name == "Black Locust" ~ "purple",
    common_name == "Sugar Maple" ~ "darkpurple",
    common_name == "Staghorn Sumac" ~ "blue",
    common_name == "Eastern Cottonwood" ~ "beige",
    common_name == "Apple" ~ "yellow",
    common_name == "American Basswood" ~ "pink",
    common_name == "River Birch" ~ "lightred",
    common_name == "White Birch" ~ "cadetblue",
    common_name == "Ginkgo" ~ "lightgray"
  ))

icons <- awesomeIcons(
  icon = 'ios-close',
  iconColor = 'white',
  library = 'ion',
  markerColor = trees$color)

leaflet(trees) %>% 
  addTiles() %>%
  addAwesomeMarkers(~lon, ~lat,
                    icon=icons,
                    label = paste("Tag:", trees$tag, "|",
                    "Species:", trees$common_name,
                    "Observation count", count(trees$tag)))

tags <- d_filtered %>%
  filter(month >= 8) %>%
  ggplot(aes(x = month, y = intensity)) +
  geom_line()
