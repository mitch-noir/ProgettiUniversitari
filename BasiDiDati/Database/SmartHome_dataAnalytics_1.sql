-- ------------------------------------------------------ --
--						  ANALYTICS 1			 		  --
-- ------------------------------------------------------ --
-- questo codice impiega almeno 140 secondi  per la sua esecuzione e relativo fetching dei dati

-- Parametri per Apriori:
set @Conf = 0.6;
set @Support = 0.05; 

set session group_concat_max_len = 10000;

with luci as (select Id from ElementoIlluminazione)
select group_concat(concat(' ID_', Id, ' int default 0 '))
from luci 
into @pivot_table; 

set @pivot_table = concat('create table transazione(',
						  ' Numero int auto_increment primary key, ', 
                            @pivot_table, 
						  ' )engine = InnoDB default charset = latin1;');
drop table if exists transazione;
prepare sql_statement1 from @pivot_table;
execute sql_statement1;

drop procedure if exists transazioni;
delimiter $$

create procedure transazioni()
begin 	
	declare attrSomma_ text default '';
    declare maxId_ INT default 0;
    declare i INT default 1;
    
	truncate table Transazione;
	set @ora = 0;
    set @insert_row = NULL;
	while @ora < 24 do
		set @minuti = 0;
		while @minuti < 60 do
			WITH	lista as (select id from ElementoIlluminazione),
                    lista_pivot as (	
							SELECT l.Id, (IF(dev.IdElementoIlluminazione IS NULL, 0, dev.IdElementoIlluminazione)) as Occorrenza
							FROM ( 
									SELECT s.*
                                    FROM selezione s INNER JOIN ImpostazioneIlluminazione il ON il.Numero = s.NumeroImpostazione  AND il.IdElementoIlluminazione = s.IdElementoIlluminazione
									WHERE 	HOUR(s.TspInizio) = @ora AND
										(MINUTE(s.TspInizio) BETWEEN  @minuti AND @minuti + 19)
										OR il.IdElementoIlluminazione IS NULL) AS dev 
							RIGHT OUTER JOIN lista l on l.Id = dev.IdElementoIlluminazione
							GROUP BY l.Id)
					SELECT group_concat(concat(Occorrenza))
					from lista_pivot into @row_values;
                    
                    set @row_values = concat('(',@row_values,')'); -- creo una riga di insert del tipo (0, 1, 0, 10, 0 ... 19)				
					IF @insert_row IS NULL THEN
						set @insert_row = concat(@row_values);
					ELSE
						set @insert_row = concat(@insert_row, ' , ' ,@row_values);
					END IF;    
			set @minuti = @minuti + 20;
        end while;
        set @ora = @ora + 1;
	end while;
    
    with luci as (select Id from ElementoIlluminazione)
	select group_concat(concat(' ID_', Id))
	from luci 
	into @attr;
    
    set @insert_row = concat('insert into transazione (', @attr,
							') values ' ,@insert_row, ';');
    
    truncate table transazione;
    
    prepare sql_statement2 from @insert_row;
	execute sql_statement2;
    
    set maxId_ = (select Max(Id) FROM ElementoIlluminazione);
    
    while i < maxId_ do
		set attrSomma_ = concat(attrSomma_, 'ID_', i, '+');
        set i = i + 1;
	end while;
    
    set attrSomma_ = concat(attrSomma_, 'ID_',maxID_);
	
    -- disable safe update mode
	SET SQL_SAFE_UPDATES=0;
    
	set @blocco = concat('
		DELETE FROM transazione
		WHERE Numero IN (SELECT *
							from (select t.Numero
											from (
													select Numero, (', attrSomma_, ') as Somma
													from transazione ) as i INNER JOIN transazione t on t.Numero = i.Numero
							where i.Somma <= 1) as d);'
	);
	
	prepare sql_statement3 from @blocco;
	execute sql_statement3;
    
	-- enable safe update mode
	SET SQL_SAFE_UPDATES=1;
    
    select *
    from Transazione;
		
end $$
delimiter ;

call transazioni();

-- -----------------------------------------
-- 2) 	Script per l'Algoritmo Apriori
-- -----------------------------------------

-- --------------------------------------------------------------
-- 2.1)		Funzioni di utilità per l'algoritmo Apriori
-- --------------------------------------------------------------
-- Principalmente generano codice dinamico 
-- per creare le diverse tabelle ad ogni passo iterativo dell'algoritmo

drop function if exists creazione_tabella_C;
delimiter ;;
create function creazione_tabella_C(k int)
returns text deterministic
begin
	declare i int default 1;
    declare Fk_Select_ text default '';
    declare Fk_Using_ text default '';
    declare combinazione_Selezione text default '';
    declare combinazione_From text default '';
    declare item_risultanti_ text default '';
    declare conteggi_risultanti_ text default '';
    declare confidenze_risultanti_ text default '';
    declare risultato_join text default '';
    declare risultato text default '';

    while i < k do
		set Fk_Select_ = concat(Fk_Select_, 'a.Item', i, ', ');
        set combinazione_Selezione = concat(combinazione_Selezione, 'I', i, '.Item as Item', i, ', ');
        set combinazione_From = concat(combinazione_From, 'inner join Items I', i+1, ' using(Numero) \n');
        set item_risultanti_ = concat(item_risultanti_, 'Item', i, ', ');
        set conteggi_risultanti_ = concat(conteggi_risultanti_, 'Num', i, ', ');
        set confidenze_risultanti_ = concat(confidenze_risultanti_, 'Num', k, ' / Num', i, ' as `Conf', i, '`, \n\t\t');
		set i = i + 1;
    end while;
    
    set Fk_Select_ = concat(Fk_Select_, 'b.Item', k-1, ' as Item', k);
    set combinazione_Selezione = concat('Numero, ', combinazione_Selezione, 'I', i, '.Item as Item', i, ' ');
    set combinazione_From = concat('Items I1 ', combinazione_From);
    
    set risultato_join = item_risultanti_;
    set item_risultanti_ = concat(item_risultanti_, 'Item', i);
    set conteggi_risultanti_ = concat(conteggi_risultanti_, 'Num', i);
    set confidenze_risultanti_ = substring(confidenze_risultanti_, 1, char_length(confidenze_risultanti_) -5);
    set risultato_join = substring(risultato_join, 1, char_length(risultato_join) -2);
    
    set i = 1;
    while i < k-1 do
		set Fk_Using_ = concat(Fk_Using_, 'Item', i, ', ');
        set i = i+1;
    end while;
    
    if k > 2 then 
		set Fk_Using_ = substring(Fk_Using_, 1, char_length(Fk_Using_) -2);
		set Fk_Using_ = concat('using(',Fk_Using_, ') ');
	else set Fk_Using_ = '';
    end if;
    
    set risultato = concat(
						'with F',k,' as (
							select 	',Fk_Select_,'
							from 	F',(k-1),' a inner join F',(k-1),' b ', Fk_Using_,'
							where 	a.Item',k-1,' <> b.Item',k-1,'    
						),
						combinazioni as (
							select 	',combinazione_Selezione,'
							from 	',combinazione_From ,'
						),
						risultato as (
							select 	', item_risultanti_,',
									count(distinct Numero) as Num', k,'
							from 	combinazioni natural join F',k,'
							group by ',item_risultanti_,'
						)
						select 	', item_risultanti_,',
								',conteggi_risultanti_,',
						        Totale,
						        Num',k,' / Totale as Supporto, 
						        ',confidenze_risultanti_,'

						from 	risultato
								inner join F',k-1,' using(',risultato_join,');
						'); -- fine concat
	return risultato;
end;;
delimiter ;

drop function if exists creazione_tabella_F;
delimiter ;;
create function creazione_tabella_F(k int)
returns text deterministic
begin
	return concat('	select * from C', k,' 
					where Supporto > @Support;');
end;;
delimiter ;


drop function if exists create_Full_Itemset;
delimiter ;;
create function create_Full_Itemset(k int)
returns text deterministic
begin
	declare i int default 1;
	declare items text default '';
    declare Confs text default '';
    declare risultato text default '';
    
    while i < k do
		set items = concat(items, 'Item', i, ', ');
        set Confs = concat(Confs, 'Conf', i, ', ');
        set i = i + 1;
    end while;

    set risultato = concat('select ', items, ' Item', i, ', ', Confs, 'Supporto from F', k, ';');
    
    return risultato;
end;;
delimiter ;

drop procedure if exists regole_Associative;
delimiter ;;
create procedure regole_Associative(k int)
begin
	declare i int default 2;
	declare items text default 'Item1, ';
    declare Confs text default '';
    declare whereClause_Confs text default '';
    
	set @drop_Full = concat('drop table if exists F;' );
    set @create_Full = concat('create table F as ', create_Full_Itemset(k));
    
    prepare drop_Full from @drop_Full;
    prepare create_Full from @create_Full;
    execute drop_Full;
    execute create_Full;
    
    
    while i < k do
        set items = concat(items, 'Item', i, ', ');
        set Confs = concat(Confs, 'Conf', i-1, ', ');
        set whereClause_Confs = substring(Confs, 1, char_length(Confs) -2);
        set whereClause_Confs = replace(whereClause_Confs, ',', ' >= @Conf or ');
        set whereClause_Confs = concat(whereClause_Confs, '>= @Conf ');

        set @insert_Full = concat( 'insert into F (', items, Confs,'Supporto) 
									select ', items, Confs, 'Supporto from F', i, '
                                	where ', whereClause_Confs);
		
        prepare insert_Full from @insert_Full; 
        execute insert_Full;
        
        set i = i +1;
    end while;
end;;
delimiter ;

-- ---------------------------------------------------------------
-- 2.2) 	Stored Procedure Algoritmo Apriori
-- ---------------------------------------------------------------
-- La stored procedure esegue l'algoritmo iterativamente, al max fino
-- al parametro dato in ingresso, ma si ferma prima se un insieme dei itemset candidati C_k è vuota

drop procedure if exists Apriori;
delimiter ;;
create procedure Apriori(tot int)
begin
	declare k int default 2; -- k = 2 perchè le tabelle  C1 ed F1 sono state già create 
    
	
    -- --------------------------------------------
	-- 			Tabella di supporto Items 
    -- --------------------------------------------
	-- Items contiene {Tr.ID, Tr.[D_i]} per ogni Transazione T,
	-- dove Tr.[D_i] è ogni Dispositivo i della transazione.
    -- esempio: Transazione Tr1{E,B,C} -->  Items: {Tr1, E}, {Tr1, B}, {Tr1, C}
    
	select group_concat( 
			concat('select Numero, ID_', el.Id,
				   ' as Item from Transazione',
				   ' where ID_', el.Id, ' <> 0') 
			separator ' union ')
	from ElementoIlluminazione el
	into @transazione_Verticale;
    
	set @transazione_Verticale = concat('create table Items as ',
										@transazione_Verticale, ';');              
                                        
	drop table if exists Items;
	prepare create_table_Items from @transazione_Verticale;
	execute create_table_Items;	
    
	-- ----------------------------------------------------------
	-- Itemset Candidati C1
	drop table if exists C1;
	create table C1 as 
	select 	Item as Item1, 
			count(*) as Num1, 
			(select count(*) from Transazione) as Totale 
	from 	Items 
	group by Item;

	alter table C1 add column Supporto double default (Num1/Totale);
	alter table C1 modify Item1 int;
	
	
    -- Full 1-itemset
	drop table if exists F1;
	create table F1 as 
		select * from C1 where Supporto > @Support;
    
	-- -----------------------------------------
	-- LOOP Candidati C_k, Full Itemset F_k
	-- -----------------------------------------
	apriori: loop
		if k > tot then leave apriori; end if;
		
		set @cancellaC = concat('drop table if exists C', k, ';');
		set @creaC = concat('create table C',k,' as ', creazione_tabella_C(k));
		set @cancellaF = concat('drop table if exists F', k, ';');
		set @creaF = concat('create table F',k,' as ',creazione_tabella_F(k));
        
		prepare cancellaC from @cancellaC;
		prepare creaC from @creaC;
		execute cancellaC;
		execute creaC;
		
		prepare cancellaF from @cancellaF;
		prepare creaF from @creaF;
		execute cancellaF;
		execute creaF;
		
		set @check_empty = concat('select exists (select 1 from F', k,') 
									into @fineApriori;');
		prepare check_empty from @check_empty;
		execute check_empty;
		if @fineApriori = 0 then leave apriori; end if;
				
		set k = k + 1; 
	end loop;
    
	select k as NumeroIterazioniFatte, tot as IterazioniRichieste;
    
    call regole_Associative(k - 1); -- si chiama regole_Associative con K-1 perchè ..
    
    select * from F;
end;;
delimiter ;

call Apriori((select count(*) from ElementoIlluminazione));

-- ------------------
-- 3) Regole forti
-- ------------------
-- Per semplificare il codice, i nomi delle colonne sono stati semplificati:
-- Conf1 vuol dire Conf(Item1 --> Item2, Item3, ..)
-- Conf2 vuol dire Conf(Item1, Item2 --> Item3, ..)
-- Conf3 vuol dire Conf(Item1, Item2, Item3 --> Item4, ..)
-- ...
-- Num1 vuol dire Cardinalità dell'insieme {Item1} in Transazione
-- Num2 vuol dire Cardinalità dell'insieme {Item1, Item2} in Transazione
-- Num3 vuol dire Cardinalità dell'insieme {Item1, Item2, Item3} in Transazione ...



