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


```