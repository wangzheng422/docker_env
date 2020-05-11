# data analyze

```python
# import pandas
import pandas as pd

# load cancer data into data frame
df = pd.read_csv('cancer_data.csv')
# display first five rows of data
df.head()

import pandas as pd

df = pd.read_csv('student_scores.csv')

df.head()

df = pd.read_csv('student_scores.csv', sep=':')
df.head()

df = pd.read_csv('student_scores.csv', header=2)
df.head()

df = pd.read_csv('student_scores.csv', header=None)
df.head()

labels = ['id', 'name', 'attendance', 'hw', 'test1', 'project1', 'test2', 'project2', 'final']
df = pd.read_csv('student_scores.csv', names=labels)
df.head()

labels = ['id', 'name', 'attendance', 'hw', 'test1', 'project1', 'test2', 'project2', 'final']
df = pd.read_csv('student_scores.csv', header=0, names=labels)
df.head()

df = pd.read_csv('student_scores.csv', index_col='Name')
df.head()

df = pd.read_csv('student_scores.csv', index_col=['Name', 'ID'])
df.head()

df_cancer = pd.read_csv('cancer_data.csv', index_col='id')
df_cancer.head()

new_column_labels = ['temperature', 'exhaust_vacuum', 'pressure', 'humidity', 'energy_output']
df_powerplant = pd.read_csv('powerplant_data.csv', names=new_column_labels, header=0)
df_powerplant.head()

df_powerplant.to_csv('powerplant_data_edited.csv')

df = pd.read_csv('powerplant_data_edited.csv')
df.head()

import pandas as pd

df = pd.read_csv('cancer_data.csv')
df.head()

# this returns a tuple of the dimensions of the dataframe
df.shape

# this returns the datatypes of the columns
df.dtypes

# although the datatype for diagnosis appears to be object, further
# investigation shows it's a string
type(df['diagnosis'][0])

# this displays a concise summary of the dataframe,
# including the number of non-null values in each column
df.info()

# this returns the number of unique values in each column
df.nunique()

# this returns useful descriptive statistics for each column of data
df.describe()

# this returns the first few lines in our dataframe
# by default, it returns the first five
df.head()

# although, you can specify however many rows you'd like returned
df.head(20)

# same thing applies to `.tail()` which returns the last few rows
df.tail(2)

# View the index number and label for each column
for i, v in enumerate(df.columns):
    print(i, v)

# select all the columns from 'id' to the last mean column
df_means = df.loc[:,'id':'fractal_dimension_mean']
df_means.head()

# repeat the step above using index numbers
df_means = df.iloc[:,:12]
df_means.head()

df_means.to_csv('cancer_data_means.csv', index=False)

# import
import numpy as np

# create the standard errors dataframe
df_SE = df.iloc[:, np.r_[:2, 12:22]]

# view the first few rows to confirm this was successful
df_SE.head()

# Import pandas
import pandas as pd

# Load census income data
df = pd.read_csv('census_income_data.csv')

# Work to answer the quiz questions
df.shape

df.describe()

# import pandas and load cancer data
import pandas as pd

df = pd.read_csv('cancer_data_means.csv')

# check which columns have missing values with info()
df.info()

# use means to fill in missing values
df.fillna(df.mean(), inplace=True)

# confirm your correction with info()
df.info()

# check for duplicates in the data
sum(df.duplicated())

# drop duplicates
df.drop_duplicates(inplace=True)

# confirm correction by rechecking for duplicates in the data
sum(df.duplicated())

# remove "_mean" from column names
new_labels = []
for col in df.columns:
    if '_mean' in col:
        new_labels.append(col[:-5])  # exclude last 6 characters
    else:
        new_labels.append(col)

# new labels for our columns
new_labels

# assign new labels to columns in dataframe
df.columns = new_labels

# display first few rows of dataframe to confirm changes
df.head()

# save this for later
df.to_csv('cancer_data_edited.csv', index=False)

# imports and load data
import pandas as pd
% matplotlib inline

df = pd.read_csv('powerplant_data_edited.csv')
df.head()

# plot relationship between temperature and electrical output
df.plot(x='temperature', y='energy_output', kind='scatter');

# plot distribution of humidity
df['humidity'].hist();

df['temperature'].plot(kind='box');

# imports and load data
import pandas as pd
% matplotlib inline

df = pd.read_csv('store_data.csv')
df.head()

# explore data
df.hist(figsize=(8, 8));

df.tail(20)

# total sales for the last month
df.iloc[196:, 1:].sum()

# average sales
df.mean()

# sales on march 13, 2016
df[df['week'] == '2016-03-13']

# worst week for store C
df[df['storeC'] == df['storeC'].min()]

# imports and load data
import pandas as pd
% matplotlib inline

df = pd.read_csv('store_data.csv')
df.head()

# explore data
df.tail(20)

# sales for the last month
df.iloc[196:, 1:].sum().plot(kind='bar');

# average sales
df.mean().plot(kind='pie');

# sales for the week of March 13th, 2016
sales = df[df['week'] == '2016-03-13']
sales.iloc[0, 1:].plot(kind='bar');

# sales for the lastest 3-month periods
last_three_months = df[df['week'] >= '2017-12-01']
last_three_months.iloc[:, 1:].sum().plot(kind='pie')

import pandas as pd

red_df = pd.read_csv('winequality-red.csv', sep=';')
white_df = pd.read_csv('winequality-white.csv', sep=';')

print(red_df.shape)
red_df.head()

print(white_df.shape)
white_df.head()

white_df.duplicated().sum()

white_df.quality.nunique()

red_df.density.mean()

# import numpy and pandas
import numpy as np
import pandas as pd

# load red and white wine datasets
red_df = pd.read_csv('winequality-red.csv', sep=';')
white_df = pd.read_csv('winequality-white.csv', sep=';')
red_df.rename(columns={'total_sulfur-dioxide':'total_sulfur_dioxide'}, inplace=True)

# create color array for red dataframe
color_red = np.repeat('red', red_df.shape[0])

# create color array for white dataframe
color_white = np.repeat('white', white_df.shape[0])

red_df['color'] = color_red
red_df.head()

white_df['color'] = color_white
white_df.head()

# append dataframes
wine_df = red_df.append(white_df) 

# view dataframe to check for success
wine_df.head()

wine_df.to_csv('winequality_edited.csv', index=False)

# import numpy and pandas
import numpy as np
import pandas as pd

# load red and white wine datasets
red_df = pd.read_csv('winequality-red.csv', sep=';')
white_df = pd.read_csv('winequality-white.csv', sep=';')

# create color array for red dataframe
color_red = np.repeat('red', red_df.shape[0])

# create color array for white dataframe
color_white = np.repeat('white', white_df.shape[0])

red_df['color'] = color_red
red_df.head()

white_df['color'] = color_white
white_df.head()

# append dataframes
wine_df = red_df.append(white_df) 

# view dataframe to check for success
wine_df.head()

# Load dataset
import pandas as pd
import matplotlib.pyplot as plt
df = pd.read_csv('winequality_edited.csv')

df.head()

df.fixed_acidity.hist();

df.total_sulfur_dioxide.hist();

df.pH.hist();

df.alcohol.hist();

df.plot(x="volatile_acidity", y="quality", kind="scatter");

df.plot(x="residual_sugar", y="quality", kind="scatter");

df.plot(x="pH", y="quality", kind="scatter");

df.plot(x="alcohol", y="quality", kind="scatter");

# Load `winequality_edited.csv`
import pandas as pd

df = pd.read_csv('winequality_edited.csv')

# Find the mean quality of each wine type (red and white) with groupby
df.groupby('color').mean().quality

# View the min, 25%, 50%, 75%, max pH values with Pandas describe
df.describe().pH

# Bin edges that will be used to "cut" the data into groups
bin_edges = [2.72, 3.11, 3.21, 3.32, 4.01] # Fill in this list with five values you just found

# Labels for the four acidity level groups
bin_names = ['high', 'mod_high', 'medium', 'low'] # Name each acidity level category

# Creates acidity_levels column
df['acidity_levels'] = pd.cut(df['pH'], bin_edges, labels=bin_names)

# Checks for successful creation of this column
df.head()

# Find the mean quality of each acidity level with groupby
df.groupby('acidity_levels').mean().quality

# Save changes for the next section
df.to_csv('winequality_edited.csv', index=False)

# selecting malignant records in cancer data
df_m = df[df['diagnosis'] == 'M']
df_m = df.query('diagnosis == "M"')

# selecting records of people making over $50K
df_a = df[df['income'] == ' >50K']
df_a = df.query('income == " >50K"')

# selecting records in cancer data with radius greater than the median
df_h = df[df['radius'] > 13.375]
df_h = df.query('radius > 13.375')

# Load 'winequality_edited.csv,' a file you created in a previous section 
import pandas as pd

df = pd.read_csv('winequality_edited.csv')
df.head()

# get the median amount of alcohol content
df.alcohol.median()

# select samples with alcohol content less than the median
low_alcohol = df.query('alcohol < 10.3')

# select samples with alcohol content greater than or equal to the median
high_alcohol = df.query('alcohol >= 10.3')

# ensure these queries included each sample exactly once
num_samples = df.shape[0]
num_samples == low_alcohol['quality'].count() + high_alcohol['quality'].count() # should be True

# get mean quality rating for the low alcohol and high alcohol groups
low_alcohol.quality.mean(), high_alcohol.quality.mean()

# get the median amount of residual sugar
df.residual_sugar.median()

# select samples with residual sugar less than the median
low_sugar = df.query('residual_sugar < 3')

# select samples with residual sugar greater than or equal to the median
high_sugar = df.query('residual_sugar >= 3')

# ensure these queries included each sample exactly once
num_samples == low_sugar['quality'].count() + high_sugar['quality'].count() # should be True

# get mean quality rating for the low sugar and high sugar groups
low_sugar.quality.mean(), high_sugar.quality.mean()

import matplotlib.pyplot as plt
% matplotlib inline

plt.bar([1, 2, 3], [224, 620, 425]);

# plot bars
plt.bar([1, 2, 3], [224, 620, 425])

# specify x coordinates of tick labels and their labels
plt.xticks([1, 2, 3], ['a', 'b', 'c']);

# plot bars with x tick labels
plt.bar([1, 2, 3], [224, 620, 425], tick_label=['a', 'b', 'c']);

plt.bar([1, 2, 3], [224, 620, 425], tick_label=['a', 'b', 'c'])
plt.title('Some Title')
plt.xlabel('Some X Label')
plt.ylabel('Some Y Label');

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
% matplotlib inline
import seaborn as sns
sns.set_style('darkgrid')

wine_df = pd.read_csv('winequality_edited.csv')

# get counts for each rating and color
color_counts = wine_df.groupby(['color', 'quality']).count()['pH']
color_counts

# get total counts for each color
color_totals = wine_df.groupby('color').count()['pH']
color_totals

# get proportions by dividing red rating counts by total # of red samples
red_proportions = color_counts['red'] / color_totals['red']
red_proportions

# get proportions by dividing white rating counts by total # of white samples
white_proportions = color_counts['white'] / color_totals['white']
white_proportions

ind = np.arange(len(red_proportions))  # the x locations for the groups
width = 0.35       # the width of the bars

# plot bars
red_bars = plt.bar(ind, red_proportions, width, color='r', alpha=.7, label='Red Wine')
white_bars = plt.bar(ind + width, white_proportions, width, color='w', alpha=.7, label='White Wine')

# title and labels
plt.ylabel('Proportion')
plt.xlabel('Quality')
plt.title('Proportion by Wine Color and Quality')
locations = ind + width / 2  # xtick locations
labels = ['3', '4', '5', '6', '7', '8', '9']  # xtick labels
plt.xticks(locations, labels)

# legend
plt.legend()

red_proportions['9'] = 0
red_proportions

# load datasets
import pandas as pd

df_08 = pd.read_csv('all_alpha_08.csv') 
df_18 = pd.read_csv('all_alpha_18.csv')

# view 2008 dataset
df_08.head(1)

# view 2018 dataset
df_18.head(1)

# drop columns from 2008 dataset
df_08.drop(['Stnd', 'Underhood ID', 'FE Calc Appr', 'Unadj Cmb MPG'], axis=1, inplace=True)

# confirm changes
df_08.head(1)

# drop columns from 2018 dataset
df_18.drop(['Stnd', 'Stnd Description', 'Underhood ID', 'Comb CO2'], axis=1, inplace=True)

# confirm changes
df_18.head(1)

# rename Sales Area to Cert Region
df_08.rename(columns={'Sales Area': 'Cert Region'}, inplace=True)

# confirm changes
df_08.head(1)

# replace spaces with underscores and lowercase labels for 2008 dataset
df_08.rename(columns=lambda x: x.strip().lower().replace(" ", "_"), inplace=True)

# confirm changes
df_08.head(1)

# replace spaces with underscores and lowercase labels for 2018 dataset
df_18.rename(columns=lambda x: x.strip().lower().replace(" ", "_"), inplace=True)

# confirm changes
df_18.head(1)

# confirm column labels for 2008 and 2018 datasets are identical
df_08.columns == df_18.columns

# make sure they're all identical like this
(df_08.columns == df_18.columns).all()

# save new datasets for next section
df_08.to_csv('data_08_v1.csv', index=False)
df_18.to_csv('data_18_v1.csv', index=False)

# load datasets
import pandas as pd

df_08 = pd.read_csv('data_08_v1.csv')
df_18 = pd.read_csv('data_18_v1.csv')

# view dimensions of dataset
df_08.shape

# view dimensions of dataset
df_18.shape

# filter datasets for rows following California standards
df_08 = df_08.query('cert_region == "CA"')
df_18 = df_18.query('cert_region == "CA"')

# confirm only certification region is California
df_08['cert_region'].unique()

# confirm only certification region is California
df_18['cert_region'].unique()

# drop certification region columns form both datasets
df_08.drop('cert_region', axis=1, inplace=True)
df_18.drop('cert_region', axis=1, inplace=True)

df_08.shape

df_18.shape

# view missing value count for each feature in 2008
df_08.isnull().sum()

# view missing value count for each feature in 2018
df_18.isnull().sum()

# drop rows with any null values in both datasets
df_08.dropna(inplace=True)
df_18.dropna(inplace=True)

# checks if any of columns in 2008 have null values - should print False
df_08.isnull().sum().any()

# checks if any of columns in 2018 have null values - should print False
df_18.isnull().sum().any()

# print number of duplicates in 2008 and 2018 datasets
print(df_08.duplicated().sum())
print(df_18.duplicated().sum())

# drop duplicates in both datasets
df_08.drop_duplicates(inplace=True)
df_18.drop_duplicates(inplace=True)

# print number of duplicates again to confirm dedupe - should both be 0
print(df_08.duplicated().sum())
print(df_18.duplicated().sum())

# save progress for the next section
df_08.to_csv('data_08_v2.csv', index=False)
df_18.to_csv('data_18_v2.csv', index=False)

# load datasets
import pandas as pd
df_08 = pd.read_csv('data_08_v2.csv')
df_18 = pd.read_csv('data_18_v2.csv') 

# check value counts for the 2008 cyl column
df_08['cyl'].value_counts()

# Extract int from strings in the 2008 cyl column
df_08['cyl'] = df_08['cyl'].str.extract('(\d+)').astype(int)

# Check value counts for 2008 cyl column again to confirm the change
df_08['cyl'].value_counts()

# convert 2018 cyl column to int
df_18['cyl'] = df_18['cyl'].astype(int)

df_08.to_csv('data_08_v3.csv', index=False)
df_18.to_csv('data_18_v3.csv', index=False)

# load datasets
import pandas as pd

df_08 = pd.read_csv('data_08_v3.csv')
df_18 = pd.read_csv('data_18_v3.csv')
df_08.air_pollution_score

df_08[df_08.air_pollution_score == '6/4']

# First, let's get all the hybrids in 2008
hb_08 = df_08[df_08['fuel'].str.contains('/')]
hb_08

# hybrids in 2018
hb_18 = df_18[df_18['fuel'].str.contains('/')]
hb_18

# create two copies of the 2008 hybrids dataframe
df1 = hb_08.copy()  # data on first fuel type of each hybrid vehicle
df2 = hb_08.copy()  # data on second fuel type of each hybrid vehicle

# Each one should look like this
df1

# columns to split by "/"
split_columns = ['fuel', 'air_pollution_score', 'city_mpg', 'hwy_mpg', 'cmb_mpg', 'greenhouse_gas_score']

# apply split function to each column of each dataframe copy
for c in split_columns:
    df1[c] = df1[c].apply(lambda x: x.split("/")[0])
    df2[c] = df2[c].apply(lambda x: x.split("/")[1])

# this dataframe holds info for the FIRST fuel type of the hybrid
# aka the values before the "/"s
df1

# this dataframe holds info for the SECOND fuel type of the hybrid
# aka the values after the "/"s
df2

# combine dataframes to add to the original dataframe
new_rows = df1.append(df2)

# now we have separate rows for each fuel type of each vehicle!
new_rows

# drop the original hybrid rows
df_08.drop(hb_08.index, inplace=True)

# add in our newly separated rows
df_08 = df_08.append(new_rows, ignore_index=True)

# check that all the original hybrid rows with "/"s are gone
df_08[df_08['fuel'].str.contains('/')]

df_08.shape

# create two copies of the 2018 hybrids dataframe, hb_18
df1 = hb_18.copy()
df2 = hb_18.copy()

# list of columns to split
split_columns = ['fuel', 'city_mpg', 'hwy_mpg', 'cmb_mpg']

# apply split function to each column of each dataframe copy
for c in split_columns:
    df1[c] = df1[c].apply(lambda x: x.split("/")[0])
    df2[c] = df2[c].apply(lambda x: x.split("/")[1])

# append the two dataframes
new_rows = df1.append(df2)

# drop each hybrid row from the original 2018 dataframe
# do this by using Pandas drop function with hb_18's index
df_18.drop(hb_18.index, inplace=True)

# append new_rows to df_18
df_18 = df_18.append(new_rows, ignore_index=True)

# check that they're gone
df_18[df_18['fuel'].str.contains('/')]

df_18.shape

# convert string to float for 2008 air pollution column
df_08.air_pollution_score = df_08.air_pollution_score.astype(float)

# convert int to float for 2018 air pollution column
df_18.air_pollution_score = df_18.air_pollution_score.astype(float)

df_08.to_csv('data_08_v4.csv', index=False)
df_18.to_csv('data_18_v4.csv', index=False)



```