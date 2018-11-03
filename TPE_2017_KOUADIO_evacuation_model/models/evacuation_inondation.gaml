/**
 *  evacuationgoto
 *  Author: 
 *  Description: 
 */

model evacuationgoto

global {
	
	file shp_Route <- shape_file("../includes/Route.shp");
	file shp_Refuge <- shape_file("../includes/Refuge.shp");
	file shp_environnement <- file("../includes/Environnement.shp");
	file shp_Panneau <- file("../includes/Panneaux.shp");
	file shp_Building <- file("../includes/Building.shp");
	geometry shape <- envelope(shp_environnement);
	int nb_cols <- 50;
	int nb_rows <- 50;
	int compteur <-0;
	int totalcompteur <-0;
	int totalmort<-0;
	float people_size <- 5.0;
	int maximal_turn <- 90; //in degree
	int nb_personne <- 150;
	float size_pluivio <- 2.0;
	float size_pluivio_max <- 100.0;
	float size_seuil<-size_pluivio_max/3;
	//bool arreter<- false;
	
	bool arretersim<-false;
    reflex finsim when:(size_pluivio >=size_pluivio_max){ do halt;}
	//parametre de sortie
	 
    float taux_sauvtage update: totalcompteur/nb_personne;
   // float taux_non_sauve update: totalmort/nb_personne;
	graph graph_from_grid;
	
	init {
		geometry free_space <- copy (shape);
		create Refuge from: shp_Refuge;
		create Building from: shp_Building {free_space <- free_space - (shape + people_size);}
		create Panneau from: shp_Panneau;
		create Route from: shp_Route {
			ask cell overlapping self {
				is_wall <- true;
				color <- #magenta;
			}
			free_space <- free_space - shape;
		}
		create Personne number: nb_personne{
			location <- any_location_in (free_space);
			target <- any_location_in(one_of(Refuge));
			
		}
		
		create Pluiviometre number: 1{
				location <- [20, 175];
		}
		graph_from_grid <- grid_cells_to_graph(cell where not each.is_wall);
	}
}

grid cell width: nb_cols height: nb_rows neighbours: 8 {
	bool is_wall <- false;
	rgb color <- #white;	
}

species Building {
	float height <- 3.0 + rnd(50);
	rgb color <- rnd_color(255);
	aspect default {
		draw shape color: color depth: height;
	}
}

species Panneau {
	aspect default {
		draw shape color: #red;
	}
}

species Refuge {
	aspect default {
		draw shape color: #blue;
		//draw square(8) color: #green;
	}
}

species Route {
	aspect default {
		draw shape color: #black;
	}
}

species Personne skills: [moving]{
	float size <- people_size;
	//float totalmort<-(nb_personne-totalcompteur);
	
	int heading max: heading + maximal_turn min: heading - maximal_turn;
	point target;
	rgb color <- rnd_color(255);
	reflex move {
		if(size_pluivio >= size_seuil ){
			do goto target: target speed: 1 on: graph_from_grid;
			if (location = target) {
				compteur<-compteur+1;
				totalcompteur<-compteur;
				totalmort<-nb_personne-totalcompteur;
				write "nombre personnes sauvées " +totalcompteur;
				do die;
			}
		}
	
	}
	reflex mourrir when: time >=600{
		if(size_pluivio > size_pluivio_max-1 ){
			do die;
			
			//arretersim<-true;
		}
		
	}
	aspect default {
		draw pyramid(size) color: color;
		draw sphere(size/3) at: {location.x,location.y,size} color: color;
	}
}

species Pluiviometre skills:[]{
	//int compteur <-nil;
	rgb color <- rgb(116, 208, 241) ;
	float monterEau;
	init {
	monterEau <- rnd(5) * 0.1;
		//speed <-10.0;
	}
	reflex augmentation {
		if (size_pluivio < size_pluivio_max){
			size_pluivio <- size_pluivio + 0.1;			
		}
	}
	
	aspect default {	
		draw box(25,50,size_pluivio)  color:color;
		//else{draw box(10,10,size_pluivio) color:#red;}	
	}
}

experiment evacuationgoto type: gui {
	parameter "Niveau de danger de l'eau" var: size_pluivio_max min: 5 max: 1000;
	parameter "Nombre Personne dans la zone à risque" var: nb_personne min: 5 max: 1000;
	
	output {
		display map type: opengl{
			//image "../images/floor.jpg";
			species Route refresh: false;
			species Building refresh: false;
			species Refuge refresh: false;
			species Panneau refresh:false;
			species Personne;
			species Pluiviometre;	
		}
		 //affichage de la statistique
		display Series_Stat_Display{
            	chart "Statistique " type: series {
            		data "niveau de l'eau" value: size_pluivio color: #blue;
               		data "Nombre de personne  " value: nb_personne color: #orange;
                	//data "Nombre de deces" value: totalmort color: #black;
                	data "Pourcentage sauve" value: totalcompteur color: #red;
                //data "Pourcentage deces" value: totalmort color: #orange;
            }
        }
	}
}
