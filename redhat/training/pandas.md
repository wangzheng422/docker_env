# pandas

https://github.com/udacity/AIPND

https://github.com/ranamahmud/AIPND/blob/master/Pandas%20Mini-Project/Statistics%20from%20Stock%20Data.ipynb

```python
import pandas as pd
# We import Pandas as pd into Python
import pandas as pd

# We create a Pandas Series that stores a grocery list
groceries = pd.Series(data = [30, 6, 'Yes', 'No'], index = ['eggs', 'apples', 'milk', 'bread'])

# We display the Groceries Pandas Series
groceries
# We print some information about Groceries
print('Groceries has shape:', groceries.shape)
print('Groceries has dimension:', groceries.ndim)
print('Groceries has a total of', groceries.size, 'elements')
# We print the index and data of Groceries
print('The data in Groceries is:', groceries.values)
print('The index of Groceries is:', groceries.index)
# We check whether bananas is a food item (an index) in Groceries
x = 'bananas' in groceries

# We check whether bread is a food item (an index) in Groceries
y = 'bread' in groceries

# We print the results
print('Is bananas an index label in Groceries:', x)
print('Is bread an index label in Groceries:', y)

# We access elements in Groceries using index labels:

# We use a single index label
print('How many eggs do we need to buy:', groceries['eggs'])
print()

# we can access multiple index labels
print('Do we need milk and bread:\n', groceries[['milk', 'bread']]) 
print()

# we use loc to access multiple index labels
print('How many eggs and apples do we need to buy:\n', groceries.loc[['eggs', 'apples']]) 
print()

# We access elements in Groceries using numerical indices:

# we use multiple numerical indices
print('How many eggs and apples do we need to buy:\n',  groceries[[0, 1]]) 
print()

# We use a negative numerical index
print('Do we need bread:\n', groceries[[-1]]) 
print()

# We use a single numerical index
print('How many eggs do we need to buy:', groceries[0]) 
print()
# we use iloc to access multiple numerical indices
print('Do we need milk and bread:\n', groceries.iloc[[2, 3]]) 

# We display the original grocery list
print('Original Grocery List:\n', groceries)

# We change the number of eggs to 2
groceries['eggs'] = 2

# We display the changed grocery list
print()
print('Modified Grocery List:\n', groceries)

# We display the original grocery list
print('Original Grocery List:\n', groceries)

# We remove apples from our grocery list. The drop function removes elements out of place
print()
print('We remove apples (out of place):\n', groceries.drop('apples'))

# When we remove elements out of place the original Series remains intact. To see this
# we display our grocery list again
print()
print('Grocery List after removing apples out of place:\n', groceries)

# We display the original grocery list
print('Original Grocery List:\n', groceries)

# We remove apples from our grocery list in place by setting the inplace keyword to True
groceries.drop('apples', inplace = True)

# When we remove elements in place the original Series its modified. To see this
# we display our grocery list again
print()
print('Grocery List after removing apples in place:\n', groceries)

# We create a Pandas Series that stores a grocery list of just fruits
fruits= pd.Series(data = [10, 6, 3,], index = ['apples', 'oranges', 'bananas'])

# We display the fruits Pandas Series
fruits

# We print fruits for reference
print('Original grocery list of fruits:\n ', fruits)

# We perform basic element-wise operations using arithmetic symbols
print()
print('fruits + 2:\n', fruits + 2) # We add 2 to each item in fruits
print()
print('fruits - 2:\n', fruits - 2) # We subtract 2 to each item in fruits
print()
print('fruits * 2:\n', fruits * 2) # We multiply each item in fruits by 2 
print()
print('fruits / 2:\n', fruits / 2) # We divide each item in fruits by 2
print()

# We import NumPy as np to be able to use the mathematical functions
import numpy as np

# We print fruits for reference
print('Original grocery list of fruits:\n', fruits)

# We apply different mathematical functions to all elements of fruits
print()
print('EXP(X) = \n', np.exp(fruits))
print() 
print('SQRT(X) =\n', np.sqrt(fruits))
print()
print('POW(X,2) =\n',np.power(fruits,2)) # We raise all elements of fruits to the power of 2

# We print fruits for reference
print('Original grocery list of fruits:\n ', fruits)
print()

# We add 2 only to the bananas
print('Amount of bananas + 2 = ', fruits['bananas'] + 2)
print()

# We subtract 2 from apples
print('Amount of apples - 2 = ', fruits.iloc[0] - 2)
print()

# We multiply apples and oranges by 2
print('We double the amount of apples and oranges:\n', fruits[['apples', 'oranges']] * 2)
print()

# We divide apples and oranges by 2
print('We half the amount of apples and oranges:\n', fruits.loc[['apples', 'oranges']] / 2)

# We multiply our grocery list by 2
groceries * 2

import pandas as pd

# Create a Pandas Series that contains the distance of some planets from the Sun.
# Use the name of the planets as the index to your Pandas Series, and the distance
# from the Sun as your data. The distance from the Sun is in units of 10^6 km

distance_from_sun = [149.6, 1433.5, 227.9, 108.2, 778.6]

planets = ['Earth','Saturn', 'Mars','Venus', 'Jupiter']

# Create a Pandas Series using the above data, with the name of the planets as
# the index and the distance from the Sun as your data.
dist_planets = pd.Series(data = distance_from_sun, index = planets)


# Calculate the number of minutes it takes sunlight to reach each planet. You can
# do this by dividing the distance from the Sun for each planet by the speed of light.
# Since in the data above the distance from the Sun is in units of 10^6 km, you can
# use a value for the speed of light of c = 18, since light travels 18 x 10^6 km/minute.
time_light = dist_planets / 18

# Use Boolean indexing to select only those planets for which sunlight takes less
# than 40 minutes to reach them.
close_planets = time_light[time_light < 40]


# We import Pandas as pd into Python
import pandas as pd

# We create a dictionary of Pandas Series 
items = {'Bob' : pd.Series(data = [245, 25, 55], index = ['bike', 'pants', 'watch']),
         'Alice' : pd.Series(data = [40, 110, 500, 45], index = ['book', 'glasses', 'bike', 'pants'])}

# We print the type of items to see that it is a dictionary
print(type(items))

# We create a Pandas DataFrame by passing it a dictionary of Pandas Series
shopping_carts = pd.DataFrame(items)

# We display the DataFrame
shopping_carts

# We create a dictionary of Pandas Series without indexes
data = {'Bob' : pd.Series([245, 25, 55]),
        'Alice' : pd.Series([40, 110, 500, 45])}

# We create a DataFrame
df = pd.DataFrame(data)

# We display the DataFrame
df

# We print some information about shopping_carts
print('shopping_carts has shape:', shopping_carts.shape)
print('shopping_carts has dimension:', shopping_carts.ndim)
print('shopping_carts has a total of:', shopping_carts.size, 'elements')
print()
print('The data in shopping_carts is:\n', shopping_carts.values)
print()
print('The row index in shopping_carts is:', shopping_carts.index)
print()
print('The column index in shopping_carts is:', shopping_carts.columns)

# We Create a DataFrame that only has Bob's data
bob_shopping_cart = pd.DataFrame(items, columns=['Bob'])

# We display bob_shopping_cart
bob_shopping_cart

# We Create a DataFrame that only has selected items for both Alice and Bob
sel_shopping_cart = pd.DataFrame(items, index = ['pants', 'book'])

# We display sel_shopping_cart
sel_shopping_cart

# We Create a DataFrame that only has selected items for Alice
alice_sel_shopping_cart = pd.DataFrame(items, index = ['glasses', 'bike'], columns = ['Alice'])

# We display alice_sel_shopping_cart
alice_sel_shopping_cart

# We create a dictionary of lists (arrays)
data = {'Integers' : [1,2,3],
        'Floats' : [4.5, 8.2, 9.6]}

# We create a DataFrame 
df = pd.DataFrame(data)

# We display the DataFrame
df

# We create a dictionary of lists (arrays)
data = {'Integers' : [1,2,3],
        'Floats' : [4.5, 8.2, 9.6]}

# We create a DataFrame and provide the row index
df = pd.DataFrame(data, index = ['label 1', 'label 2', 'label 3'])

# We display the DataFrame
df

# We create a list of Python dictionaries
items2 = [{'bikes': 20, 'pants': 30, 'watches': 35}, 
          {'watches': 10, 'glasses': 50, 'bikes': 15, 'pants':5}]

# We create a DataFrame 
store_items = pd.DataFrame(items2)

# We display the DataFrame
store_items

# We create a list of Python dictionaries
items2 = [{'bikes': 20, 'pants': 30, 'watches': 35}, 
          {'watches': 10, 'glasses': 50, 'bikes': 15, 'pants':5}]

# We create a DataFrame  and provide the row index
store_items = pd.DataFrame(items2, index = ['store 1', 'store 2'])

# We display the DataFrame
store_items

# We print the store_items DataFrame
print(store_items)

# We access rows, columns and elements using labels
print()
print('How many bikes are in each store:\n', store_items[['bikes']])
print()
print('How many bikes and pants are in each store:\n', store_items[['bikes', 'pants']])
print()
print('What items are in Store 1:\n', store_items.loc[['store 1']])
print()
print('How many bikes are in Store 2:', store_items['bikes']['store 2'])

# We add a new column named shirts to our store_items DataFrame indicating the number of
# shirts in stock at each store. We will put 15 shirts in store 1 and 2 shirts in store 2
store_items['shirts'] = [15,2]

# We display the modified DataFrame
store_items

# We make a new column called suits by adding the number of shirts and pants
store_items['suits'] = store_items['pants'] + store_items['shirts']

# We display the modified DataFrame
store_items

# We create a dictionary from a list of Python dictionaries that will number of items at the new store
new_items = [{'bikes': 20, 'pants': 30, 'watches': 35, 'glasses': 4}]

# We create new DataFrame with the new_items and provide and index labeled store 3
new_store = pd.DataFrame(new_items, index = ['store 3'])

# We display the items at the new store
new_store

# We append store 3 to our store_items DataFrame
store_items = store_items.append(new_store)

# We display the modified DataFrame
store_items

# We add a new column using data from particular rows in the watches column
store_items['new watches'] = store_items['watches'][1:]

# We display the modified DataFrame
store_items

# We insert a new column with label shoes right before the column with numerical index 4
store_items.insert(4, 'shoes', [8,5,0])

# we display the modified DataFrame
store_items

# We remove the new watches column
store_items.pop('new watches')

# we display the modified DataFrame
store_items

# We remove the watches and shoes columns
store_items = store_items.drop(['watches', 'shoes'], axis = 1)

# we display the modified DataFrame
store_items

# We remove the store 2 and store 1 rows
store_items = store_items.drop(['store 2', 'store 1'], axis = 0)

# we display the modified DataFrame
store_items

# We change the column label bikes to hats
store_items = store_items.rename(columns = {'bikes': 'hats'})

# we display the modified DataFrame
store_items

# We change the row label from store 3 to last store
store_items = store_items.rename(index = {'store 3': 'last store'})

# we display the modified DataFrame
store_items

# We change the row index to be the data in the pants column
store_items = store_items.set_index('pants')

# we display the modified DataFrame
store_items

# We create a list of Python dictionaries
items2 = [{'bikes': 20, 'pants': 30, 'watches': 35, 'shirts': 15, 'shoes':8, 'suits':45},
{'watches': 10, 'glasses': 50, 'bikes': 15, 'pants':5, 'shirts': 2, 'shoes':5, 'suits':7},
{'bikes': 20, 'pants': 30, 'watches': 35, 'glasses': 4, 'shoes':10}]

# We create a DataFrame  and provide the row index
store_items = pd.DataFrame(items2, index = ['store 1', 'store 2', 'store 3'])

# We display the DataFrame
store_items

# We count the number of NaN values in store_items
x =  store_items.isnull().sum().sum()

# We print x
print('Number of NaN values in our DataFrame:', x)

store_items.isnull().sum()

# We print the number of non-NaN values in our DataFrame
print()
print('Number of non-NaN values in the columns of our DataFrame:\n', store_items.count())

# We drop any rows with NaN values
store_items.dropna(axis = 0)

# We drop any columns with NaN values
store_items.dropna(axis = 1)

# We replace all NaN values with 0
store_items.fillna(0)

# We replace NaN values with the previous value in the column
store_items.fillna(method = 'ffill', axis = 0)

# We replace NaN values with the previous value in the row
store_items.fillna(method = 'ffill', axis = 1)

# We replace NaN values with the next value in the column
store_items.fillna(method = 'backfill', axis = 0)

# We replace NaN values with the next value in the row
store_items.fillna(method = 'backfill', axis = 1)

# We replace NaN values by using linear interpolation using column values
store_items.interpolate(method = 'linear', axis = 0)

# We replace NaN values by using linear interpolation using row values
store_items.interpolate(method = 'linear', axis = 1)

import pandas as pd
import numpy as np

pd.set_option('precision', 1)

books = pd.Series(data = ['Great Expectations', 'Of Mice and Men', 'Romeo and Juliet', 'The Time Machine', 'Alice in Wonderland' ])
authors = pd.Series(data = ['Charles Dickens', 'John Steinbeck', 'William Shakespeare', ' H. G. Wells', 'Lewis Carroll' ])
user_1 = pd.Series(data = [3.2, np.nan ,2.5])
user_2 = pd.Series(data = [5., 1.3, 4.0, 3.8])
user_3 = pd.Series(data = [2.0, 2.3, np.nan, 4])
user_4 = pd.Series(data = [4, 3.5, 4, 5, 4.2])

dat = {'Book Title' : books,
       'Author' : authors,
       'User 1' : user_1,
       'User 2' : user_2,
       'User 3' : user_3,
       'User 4' : user_4}

book_ratings = pd.DataFrame(dat)

book_ratings.fillna(book_ratings.mean(), inplace = True)

# We load Google stock data in a DataFrame
Google_stock = pd.read_csv('./GOOG.csv')

# We print some information about Google_stock
print('Google_stock is of type:', type(Google_stock))
print('Google_stock has shape:', Google_stock.shape)

Google_stock

Google_stock.head()

Google_stock.tail()

Google_stock.isnull().any()

# We get descriptive statistics on our stock data
Google_stock.describe()

# We get descriptive statistics on a single column of our DataFrame
Google_stock['Adj Close'].describe()

# We print information about our DataFrame  
print()
print('Maximum values of each column:\n', Google_stock.max())
print()
print('Minimum Close value:', Google_stock['Close'].min())
print()
print('Average value of each column:\n', Google_stock.mean())

# We display the correlation between columns
Google_stock.corr()

# We load fake Company data in a DataFrame
data = pd.read_csv('./fake_company.csv')

data

# We display the total amount of money spent in salaries each year
data.groupby(['Year'])['Salary'].sum()

# We display the average salary per year
data.groupby(['Year'])['Salary'].mean()

# We display the total salary each employee received in all the years they worked for the company
data.groupby(['Name'])['Salary'].sum()

# We display the salary distribution per department per year.
data.groupby(['Year', 'Department'])['Salary'].sum()

```