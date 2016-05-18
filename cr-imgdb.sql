DROP TABLE IF EXISTS report;

CREATE TABLE report (
	report_id						TEXT		PRIMARY KEY		NOT NULL,
	report_nbdirsread 				TEXT 						NOT NULL,
	report_nbfilesread 				TEXT 						NOT NULL,
	report_nbdup					INTEGER						,
	report_sizelost					INTEGER						
); 

DROP TABLE IF EXISTS image;
CREATE TABLE IF NOT EXISTS image (
	img_id			TEXT		PRIMARY KEY		NOT NULL,
	img_nbocc		INTEGER						NOT NULL DEFAULT 1,
	img_size		INTEGER						NOT NULL,
	img_mtime		TEXT						NOT NULL
);

DROP TABLE IF EXISTS location;
CREATE TABLE IF NOT EXISTS location (
	loc_id						TEXT						NOT NULL,
	loc_fullname				TEXT						NOT NULL,
	loc_filename				TEXT						NOT NULL,
	loc_dir						TEXT						NOT NULL,	
	loc_ext						TEXT						NOT NULL,
	CONSTRAINT ctlocation UNIQUE (loc_id, loc_fullname)
	FOREIGN KEY(loc_id) REFERENCES image(img_id)
);