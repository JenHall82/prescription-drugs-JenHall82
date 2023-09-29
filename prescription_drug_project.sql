--1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT npi, SUM(total_claim_count) AS total_claim_count 
FROM prescriber LEFT JOIN prescription USING (npi)
GROUP BY npi
ORDER BY total_claim_count DESC NULLS LAST;

--b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.


SELECT nppes_provider_first_name, nppes_provider_last_org_name, SUM(total_claim_count) AS total_claim_count
FROM prescriber LEFT JOIN prescription USING (npi)
GROUP BY nppes_provider_first_name, nppes_provider_last_org_name
ORDER BY total_claim_count DESC NULLS LAST;

--2.  a. Which specialty had the most total number of claims (totaled over all drugs)?


SELECT DISTINCT specialty_description, SUM(total_claim_count)
FROM prescriber LEFT JOIN prescription USING (npi)
GROUP BY specialty_description
ORDER BY SUM DESC NULLS LAST;

-- b. Which specialty had the most total number of claims for opioids?

SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber LEFT JOIN prescription USING (npi) FULL JOIN drug ON prescription.drug_name = drug.drug_name
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY total_claims DESC NULLS LAST;

--c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?


SELECT specialty_description, drug_name
FROM prescriber LEFT JOIN prescription USING(npi)
WHERE drug_name IS NULL
ORDER BY drug_name DESC;

--d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

SELECT drug_name AS opioid_drug, specialty_description
FROM drug
CROSS JOIN prescriber
WHERE opioid_drug_flag = 'Y' 
GROUP BY drug_name, specialty_description
LIMIT 20;

WITH opioid_count AS (SELECT specialty_description, SUM(total_claim_count)::integer AS total_opioids
					   FROM prescriber INNER JOIN prescription USING (npi)
					  				   INNER JOIN drug USING (drug_name)
					   WHERE opioid_drug_flag = 'Y'
					   GROUP BY specialty_description)

SELECT opioid_count.specialty_description, ROUND(total_opioids/SUM(prescription.total_claim_count)*100,2) AS perc_opioid
FROM prescription INNER JOIN prescriber USING (npi) INNER JOIN opioid_count USING (specialty_description)
GROUP BY opioid_count.specialty_description, total_opioids
ORDER BY perc_opioid DESC NULLS LAST;




--3. a. Which drug (generic_name) had the highest total drug cost?

SELECT generic_name, SUM(total_drug_cost) AS total_drug_cost
FROM drug LEFT JOIN prescription USING (drug_name)
GROUP BY generic_name
ORDER BY total_drug_cost DESC NULLS LAST
LIMIT 1;

--b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**


SELECT generic_name, ROUND(SUM(total_drug_cost) / SUM(total_day_supply), 2)::money AS total_cost_per_day
FROM prescription FULL JOIN drug USING (drug_name)
GROUP BY generic_name
ORDER BY total_cost_per_day DESC NULLS LAST;

--4. a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

SELECT drug_name,
       CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	   WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	   ELSE 'neither' END AS drug_type
FROM drug;


--b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT SUM(total_drug_cost)::money AS total_cost, 
       CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	   WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	   ELSE 'neither' END AS drug_type
FROM drug INNER JOIN prescription AS presc USING (drug_name)
GROUP BY drug_type;

--5.a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT COUNT(DISTINCT cbsa)
FROM cbsa
WHERE cbsaname LIKE '%TN%';


--b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT cbsaname, SUM(population) AS total_pop
FROM cbsa LEFT JOIN population USING (fipscounty)
WHERE population IS NOT NULL
GROUP BY cbsaname
ORDER BY total_pop DESC;


--c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.


SELECT county, population, cbsa
FROM population FULL JOIN cbsa USING (fipscounty) FULL JOIN fips_county USING (fipscounty)
WHERE cbsa IS NULL AND population IS NOT NULL
ORDER BY population DESC;

--6.a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000
GROUP BY drug_name, total_claim_count
ORDER BY total_claim_count DESC;

--b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
-- c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT nppes_provider_first_name AS first_name, nppes_provider_last_org_name AS last_name, drug_name, total_claim_count,
		CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			 ELSE 'not opioid' END AS drug_type
FROM prescription FULL JOIN drug USING (drug_name) FULL JOIN prescriber ON prescription.npi = prescriber.npi
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC;

--7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.
--a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.



SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE opioid_drug_flag = 'Y' AND nppes_provider_city = 'NASHVILLE' AND specialty_description = 'Pain Management';


--b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
--c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

WITH opioids AS (SELECT npi, drug_name
				 FROM prescriber
				 CROSS JOIN drug
				 WHERE opioid_drug_flag = 'Y' AND nppes_provider_city = 'NASHVILLE' AND specialty_description = 'Pain Management')
SELECT opioids.npi, opioids.drug_name, COALESCE(CASE WHEN total_claim_count IS null THEN 0 ELSE total_claim_count END, total_claim_count) AS total_claim_count
FROM opioids LEFT JOIN prescription ON opioids.npi = prescription.npi AND opioids.drug_name = prescription.drug_name
GROUP BY opioids.npi, opioids.drug_name, total_claim_count
ORDER BY total_claim_count DESC;



--BONUS 1. How many npi numbers appear in the prescriber table but not in the prescription table?


(SELECT DISTINCT npi
FROM prescriber)
EXCEPT
(SELECT DISTINCT npi
FROM prescription);

--2.
--a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

SELECT generic_name, SUM(total_claim_count) AS total_claims
FROM drug INNER JOIN prescription USING (drug_name) INNER JOIN prescriber USING (npi)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5;

--b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

SELECT generic_name, SUM(total_claim_count) AS total_claims
FROM drug INNER JOIN prescription USING (drug_name) INNER JOIN prescriber USING (npi)
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5;

--c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.

SELECT generic_name, SUM(total_claim_count) AS total_claims
FROM drug INNER JOIN prescription USING (drug_name) INNER JOIN prescriber USING (npi)
WHERE specialty_description IN ('Cardiology', 'Family Practice')
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5;

--3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
--a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.

SELECT npi, SUM(total_claim_count) AS total_claims, nppes_provider_city AS city
FROM prescription INNER JOIN prescriber USING (npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5;

--b. Now, report the same for Memphis.

SELECT npi, SUM(total_claim_count) AS total_claims, nppes_provider_city AS city
FROM prescription INNER JOIN prescriber USING (npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5;

--c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.

SELECT npi, SUM(total_claim_count) AS total_claims, nppes_provider_city AS city
FROM prescription INNER JOIN prescriber USING (npi)
WHERE nppes_provider_city IN ('NASHVILLE', 'MEMPHIS', 'KNOXVILLE', 'CHATTANOOGA')
GROUP BY nppes_provider_city, npi
ORDER BY total_claims DESC
LIMIT 20;

--4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.

SELECT county, SUM(overdose_deaths.overdose_deaths) AS total_od_deaths
FROM overdose_deaths LEFT JOIN fips_county ON overdose_deaths.fipscounty = fips_county.fipscounty::integer
WHERE overdose_deaths > (SELECT AVG(overdose_deaths)
						 FROM overdose_deaths)
GROUP BY county
ORDER BY total_od_deaths DESC;

--5.
--a. Write a query that finds the total population of Tennessee.

SELECT SUM(population) AS tn_population
FROM population LEFT JOIN fips_county ON population.fipscounty = fips_county.fipscounty
WHERE state = 'TN';

--b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.

WITH tenn_pop AS (SELECT SUM(population) AS tn_population, fipsstate
				  FROM population LEFT JOIN fips_county ON population.fipscounty = fips_county.fipscounty
				  WHERE state = 'TN'
				  GROUP BY fipsstate)
				  
SELECT county, population, ROUND(population.population/tenn_pop.tn_population*100,2) AS percent_of_tn_pop
FROM tenn_pop INNER JOIN fips_county USING (fipsstate) INNER JOIN population USING (fipscounty)
GROUP BY county, population.population, tn_population
ORDER BY percent_of_tn_pop DESC;

		  







