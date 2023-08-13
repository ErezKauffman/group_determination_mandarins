#1st scan plots with normalized average size, yield estimation and block group  
SELECT cfrd.farmer_name, pr.project_season, pl.plot_code, cl.scan_date, cl.average_size AS average_size_1st_scan, pp.project_plot_standard_yield, scan_date_norm,
(cl.average_size + DATEDIFF(scan_date_norm, scan_date) * 0.279) AS average_size_norm_1st_scan  #row_number() over (order by pl.plot_code) cume_dist() over (partition by row_num, order by cl.average_size desc, pp.project_plot_standard_yield asc) as percent_in_data
#, rt.value 
,CASE 
	WHEN ((cl.average_size + DATEDIFF(scan_date_norm, scan_date) * 0.279) BETWEEN 33 AND 37.759) AND (pp.project_plot_standard_yield BETWEEN 4.5 AND 6) THEN ('A') ##RGR<lower_threshold gets polinomial equation of lower threshold
	WHEN ((cl.average_size + DATEDIFF(scan_date_norm, scan_date) * 0.279) BETWEEN 37.76 AND 42.499) AND (pp.project_plot_standard_yield BETWEEN 3 AND 4.499) THEN ('B') ##lower_threshold<RGR<commercial_threshold gets polinomial equation of economic threshold
	WHEN ((cl.average_size + DATEDIFF(scan_date_norm, scan_date) * 0.279) BETWEEN 42.5 AND 47.249) AND (pp.project_plot_standard_yield BETWEEN 1.5 AND 2.999) THEN ('C') ##commercial_threshold<RGR<upper_threshold gets polinomial equation of commercial threshold
	WHEN ((cl.average_size + DATEDIFF(scan_date_norm, scan_date) * 0.279) BETWEEN 47.25 AND 52) AND (pp.project_plot_standard_yield BETWEEN 0 AND 1.499) THEN ('D') ##RGR>upper threshold gets polinomial equation of upper threshold
 	ELSE 'OTHER' ##gets polinomial equation of general threshold
END AS Block_group
FROM project_plot pp
INNER JOIN (
	SELECT (DATE(FROM_UNIXTIME(AVG(UNIX_TIMESTAMP(cl.scan_date))))) AS scan_date_norm
	FROM project_plot pp
	INNER JOIN project pr 
	ON pr.project_id = pp.project_id 
	INNER JOIN (
		SELECT * FROM caliper
		GROUP BY project_plot_id 
	) AS cl 
	ON cl.project_plot_id = pp.project_plot_id 
	INNER JOIN plot pl 
	ON pl.plot_id = pp.plot_id 
	INNER JOIN 
	(
		SELECT c.customer_legal_name as farmer_name, parent_id, child_id 
		FROM customer_farmer_relation cfr 
		INNER JOIN customer c 
		ON cfr.child_id = c.customer_id 
	) AS cfrd
	ON cfrd.child_id = pl.customer_id 
	INNER JOIN customer AS company
	ON company.customer_id = cfrd.parent_id 
	WHERE company.customer_code = "MEHADN" #AND pl.plot_code IN ('01909200','03200110','15708141','21401995')
	AND project_plot_scan_date > STR_TO_DATE('01092022', '%d%m%Y')
	AND project_season = 23
	ORDER BY cl.average_size DESC ,pl.plot_code, cfrd.farmer_name, pp.project_plot_id 
) AS norm
ON TRUE
INNER JOIN project pr 
ON pr.project_id = pp.project_id 
INNER JOIN (
	SELECT * FROM caliper
	GROUP BY project_plot_id 
) AS cl 
ON cl.project_plot_id = pp.project_plot_id 
INNER JOIN plot pl 
ON pl.plot_id = pp.plot_id 
INNER JOIN 
(
	SELECT c.customer_legal_name as farmer_name, parent_id, child_id 
	FROM customer_farmer_relation cfr 
	INNER JOIN customer c 
	ON cfr.child_id = c.customer_id 
) AS cfrd
ON cfrd.child_id = pl.customer_id 
INNER JOIN customer AS company
ON company.customer_id = cfrd.parent_id 
#INNER JOIN packing_metadata pm 
#ON pm.customer_id = pr.customer_id 
#INNER JOIN rootstock_type rt 
#ON rt.rootstock_id = pl.plot_root_stock 
WHERE company.customer_code = "MEHADN" #AND pl.plot_code IN ('01909200','03200110','15708141','21401995')
AND project_plot_scan_date > STR_TO_DATE('01092022', '%d%m%Y')
AND project_season = 23
#(SELECT CASE WHEN )
ORDER BY average_size_1st_scan DESC ,pl.plot_code, cfrd.farmer_name, pp.project_plot_id 

##create one scan date and each block with his av size 
##create 4 groups of different av size distribution and grower yield estimation
##there is no connection between av size and grower yield estimation
