/**
 *  new
 *  Author: TPE 2017 KOUADIO P21 IFI
 *  Description: 
 */

model water

global torus:false{
	
	int nb_nuage <- 300 parameter:'Nombre des nuages' category:'Nuages' min:1 max:1000;
	float permabilite_sol <- 10.5 parameter:'Pemeabilite du sol' category:'Sol' min:0.0 max:1.0;
	file hanoi_polygones <- file("../includes/hanoi_polygons.shp");
	file hanoi_polylines <- file("../includes/hanoy_polylines.shp");
	geometry shape <- envelope(hanoi_polygones);

	//taille nuage & pluie
	float step <- 0.0001;
	float min_size <- 0.0001;
	float max_size <- 0.001; 
    float seille_size <- 0.001;
    //position nuage & pluie
    float x_min <- 0.001;
    float x_max <- 0.0243;
    float y_min <- 0.001;
    float y_max <- 0.0215;
    float z_nuage <- 0;
    int z_step <- 0.001;
    int nb_pluie <-50;
    // gestion niveau de l'eau
    float levelwater <-0.0;
   	bool arretersim<-false;
   	reflex finsim when:arretersim{ do halt;}
	init {
		
		float height_building <- rnd(10)*0.0001 + 0.001;
		create building from: hanoi_polygones{
			height <- height_building;
		}
		create lines from: hanoi_polylines{}
		create nuage number: nb_nuage{}
    }
}

species lines {
	rgb color <- #black ;
	aspect base {
		draw shape color: color;
	}
}

species building {
	rgb color <- rnd_color(255) ;
	float height;
	aspect base {
		draw shape color: color depth: height;
	}
}

species nuage skills:[moving] {
    rgb color <- rgb(#ECECFB);
    
    float size <- ((rnd(10) + 1) * min_size);
 	point location <- [((rnd(23)+1)*x_min), ((rnd(20)+1)*y_min), (rnd(4)+10) * 0.001];
	
	int nb_pluie <-0;
	
	reflex patrolling{
	 	do action: wander amplitude:100;
	 }
	
	reflex creation_pluie {
		if (self.size >= seille_size){
			if (self.size = seille_size){
				nb_pluie <- 100 + rnd(50);
			}
			if (self.size > seille_size){
				nb_pluie <- 100 + rnd(100);
			}
			create pluie number: nb_pluie{
				self.location <- myself.location;
			}
			create nuage_gris number: 1{
				self.location <- myself.location;
				self.size <- myself.size;
			}
			do action: die;	
		}
		else{
			if (flip(0.5)){
				set self.size <- self.size + step;	
			}
			if (flip(0.1)){
				set self.size <- self.size - step;	
			}
		}
		
	}
    aspect base {
        draw shape:sphere(size) color:color;
    }
}

species pluie skills:[moving] {
	float size <- min_size;
	float speed<-5;
	rgb color <- rgb(116, 208, 241) ;
	float pos_z <- 0.014;
	reflex creation_eau{
		if (location.z >=0){
				//speed<-speed+2;		
			set location <- [location.x, location.y, location.z-0.0003];
		}
		else{
			if (flip(permabilite_sol)){
				create eau number: 1{
					self.location <- myself.location;
									}
			}
			do action: die;	
		}	
	}
	aspect base {
        draw sphere(size) color:color;
    }
}
species eau skills:[moving] {
    rgb color<- rgb(#99E5FF);
    float sizeau <- 0.0;
    float maxi <- max_size;
	float distance_prog <- min_size;
    float height<-0.001;	
	reflex creation_inondation {
		ask target: list(self neighbours_at (distance_prog)){
			if (flip(permabilite_sol)){
				create eau number: 1{
					self.location <- myself.location;
					self.sizeau <- myself.sizeau;
				}
				do action: die;	
			}
		}
	}
	reflex patrolling{
	 	do action: wander amplitude:1;
	 	self.sizeau <- self.sizeau + (min_size);
	 	levelwater <- self.sizeau +10.0;
	 }
	aspect base {
        draw sphere((sizeau)+0.001) color:color depth:self.sizeau;
    }
}

species nuage_gris {
	rgb color <- #CECECE ; //Gris perle
    int count <- 0;
    int seuille_count <- 10;
    float size <- (rnd(10) * min_size);

	reflex compteur{
		if (seuille_count = count){
			do action: die;	
		}
		count <- count + 1;
	}
	aspect base {
        draw sphere(size) color:color;
    }
}
experiment water type: gui {
	output {
        display city_display type:opengl {
        	species building aspect: base ;
        	species nuage aspect: base ;
            species pluie aspect: base ;
            species nuage_gris aspect: base ;
            species eau aspect: base ;
            species lines aspect: base ;
        }
        display Series_Stat_Display{
            	chart "Statistique " type: series {
            		data "niveau de l'eau" value: levelwater color: #blue;
               		//data "Nombre de personne  " value: nb_personne color: #orange;
                	//data "Nombre de deces" value: totalmort color: #black;
                	//data "Pourcentage sauve" value: totalcompteur color: #red;
                //data "Pourcentage deces" value: totalmort color: #orange;
            }
        }
   }
}
