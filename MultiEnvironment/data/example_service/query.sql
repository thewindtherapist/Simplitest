SELECT DISTINCT
c.prvdr_id as 'provider_id',
c.fst_name as 'first_name',
c.lst_name as 'last_name',
c.gndr as 'gender',
a.adrs as 'address_1',
a.adrs2 as 'address_2',
a.city as 'city',
a.state as 'state',
a.zip as 'zip',
b.phn_nmbr as 'phone_number',
c.par_status,
c.accptng_nw_ptnts as 'accepting_new_patients',
c.Brd_Cert as 'board_certification',
c.Qlty_Data as 'quality_data',
e.dgr_dsply as 'degree',
g.schl_name as 'school_name',
f.grdtn_yr as 'graduation_year'
FROM [PhysicianCompare_DevB2].[dbo].PHYSN_ADRS_LP a
inner join [PhysicianCompare_DevB2].[dbo].PHYSN_PRVDR_ADRS b ON a.adrs_id = b.adrs_id
inner join [PhysicianCompare_DevB2].[dbo].PHYSN_PRVDR c ON c.prvdr_id= b.prvdr_id
inner join [PhysicianCompare_DevB2].[dbo].PHYSN_PRVDR_DGR d ON c.prvdr_id=d.prvdr_id
inner join [PhysicianCompare_DevB2].[dbo].PHYSN_DGR_LP e ON e.dgr_id=d.dgr_id
inner join [PhysicianCompare_DevB2].[dbo].PHYSN_PRVDR_SCHL f ON f.prvdr_id=c.prvdr_id
inner join [PhysicianCompare_DevB2].[dbo].PHYSN_SCHL_LP g ON g.schl_id = f.schl_id
WHERE c.lst_name LIKE '<%= query_provider_last_name %>'
AND c.fst_name LIKE '<%= query_provider_first_name %>'
