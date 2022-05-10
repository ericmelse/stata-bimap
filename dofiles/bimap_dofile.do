*------------------------- set your working directory 设置工作路径
   global path "D:/"
*------------------------- set over

cd "$path"  
cap mkdir bimap_data 
cd "D:/bimap_data"  
cap mkdir figs
global Figs "$path/bimap_data/figs"

//
// 下载所需外部程序
//   install packages required
//
ssc install bimap, replace 

net install geo2xy.pkg, replace 
net get     geo2xy.pkg, replace
ssc install spmap, replace
ssc install palettes, replace
ssc install colrspace, replace

//
// 下载基础数据
//   Download datasets for drawing maps
//
foreach file in county_race usa_county usa_county_shp_clean usa_state usa_state_shp_clean{
    copy https://github.com/asjadnaqvi/stata-bimap/raw/main/GIS/`file'.dta ., replace 	
}

// 数据处理
//   labels data
   use "usa_county", clear
   destring _all, replace
           
   merge 1:1 STATEFP COUNTYFP using county_race
   keep if _m==3
   drop _m

// save file for using as labels
   drop if inlist(STATEFP,2,15,60,66,69,72,78)
   geo2xy _CY _CX, proj(albers) replace
   compress
   save usa_county2.dta, replace  


//
// Examples
//

// Test with the spmap command:
   spmap share_afam using usa_county_shp_clean, ///
         id(_ID) clm(custom) clb(0(10)100) fcolor(Heat)

// Basic use
   bimap share_hisp share_afam using usa_county_shp_clean, ///
         cut(pctile) palette(pinkgreen)
   graph export "$Figs/bimap_fig001.png", width(1200) replace 

   bimap share_hisp share_afam using usa_county_shp_clean, ///
         cut(pctile) palette(pinkgreen) count values
   graph export "$Figs/bimap_fig002.png", width(1200) replace 

// Add additional information
   bimap share_hisp share_afam using usa_county_shp_clean, ///
         cut(pctile) palette(purpleyellow) ///
         title("My first bivariate map")   ///
	     subtitle("Made with Stata")       ///
	     note("Data from US Census Bureau.")
   graph export "$Figs/bimap_fig003.png", width(1200) replace 


// Add additional polygon layer
   bimap share_asian share_afam using usa_county_shp_clean, ///
         cut(pctile) palette(bluered)  ///
         title("{fontface Arial Bold:My first bivariate map}") ///
	     subtitle("Made with Stata")   ///
	     note("Data from the US Census Bureau.") ///      
         textx("Share of African Americans")  ///
	     texty("Share of Asians") ///
	     texts(3.5) textlabs(3) values count ///
         ocolor() osize(none) ///
         polygon(data("usa_state_shp_clean") ///
	     ocolor(white) osize(0.3))
   graph export "$Figs/bimap_fig004.png", width(1200) replace 


// a Pink version 
   bimap share_hisp share_afam using usa_county_shp_clean, ///
         cut(equal) palette(pinkgreen) count values


// More specification		 
#d ;
bimap share_hisp share_afam using usa_county_shp_clean,
      cut(pctile) palette(pinkgreen) 
	  title("{fontface Arial Bold:My first bivariate map}") 
	  subtitle("Made with Stata")
	  note("Data from the US Census Bureau. Counties with population > 100k plotted as proportional dots.", size(1.8))	
	  textx("Share of African Americans") 
	  texty("Share of Hispanics") 
	  texts(3.5) textlabs(3) values count
	  ocolor() osize(none)
	  polygon(data("usa_state_shp_clean") ocolor(white) osize(0.3))
	  point(data("usa_county2") x(_CX) y(_CY) 
	        select(keep if tot_pop>100000) 
	        proportional(tot_pop) 
	        psize(absolute) 
	        fcolor(lime%85) ocolor(black) osize(0.12) size(0.9) ) ;
#d cr
   graph export "$Figs/bimap_fig005.png", width(1200) replace
