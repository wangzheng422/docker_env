# prob

```python
# import numpy
import numpy as np

# simulate 1 million tests of two fair coin flips
tests = np.random.randint(2, size=(int(1e6), 2))

# sums of all tests
test_sums = tests.sum(axis=1)

# proportion of tests that produced exactly two heads
(test_sums == 0).mean()

# simulate 1 million tests of three fair coin flips
tests = np.random.randint(2, size=(int(1e6), 3))

# sums of all tests
test_sums = tests.sum(axis=1)

# proportion of tests that produced exactly one head
(test_sums == 2).mean()

# simulate 1 million tests of three bias coin flips
# hint: use np.random.choice()
tests = np.random.choice([0, 1], size=(int(1e6), 3), p=[0.6, 0.4])

# sums of all tests
test_sums = tests.sum(axis=1)

# proportion of tests that produced exactly one head
(test_sums == 2).mean()

# simulate 1 million tests of one die roll
tests = np.random.choice(np.arange(1, 7), size=int(1e6))

# proportion of tests that produced an even number
(tests % 2 == 0).mean()

# simulate the first million die rolls
first = np.random.choice(np.arange(6), size=int(1e6))

# simulate the second million die rolls
second = np.random.choice(np.arange(6), size=int(1e6))

# proportion of tests where the 1st and 2nd die rolled the same number
(first == second).mean()

# import numpy
import numpy as np

# simulate 1 million tests of one fair coin flip
# remember, the output of these tests are the # successes, or # heads
tests = np.random.binomial(1, 0.5, int(1e6))

# proportion of tests that produced heads
(tests == 1).mean()

# simulate 1 million tests of five fair coin flips
tests = np.random.binomial(5, 0.5, int(1e6))

# proportion of tests that produced 1 head
(tests == 1).mean()

# simulate 1 million tests of ten fair coin flips
tests = np.random.binomial(10, 0.5, int(1e6))

# proportion of tests that produced 4 heads
(tests == 4).mean()

# simulate 1 million tests of five bias coin flips
tests = np.random.binomial(5, 0.8, int(1e6))

# proportion of tests that produced 5 heads
(tests == 5).mean()

# simulate 1 million tests of ten bias coin flips
tests = np.random.binomial(10, 0.15, int(1e6))

# proportion of tests that produced at least 3 heads
(tests >= 3).mean()

# To add a new cell, type '# %%'
# To add a new markdown cell, type '# %% [markdown]'
# %% [markdown]
# # Cancer Test Results

# %%
import pandas as pd

df = pd.read_csv('cancer_test_data.csv')
df.head()


# %%
df.shape


# %%
# number of patients with cancer
df.has_cancer.sum()


# %%
# number of patients without cancer
(df.has_cancer == False).sum()


# %%
# proportion of patients with cancer
df.has_cancer.mean()


# %%
# proportion of patients without cancer
1 - df.has_cancer.mean()


# %%
# proportion of patients with cancer who test positive
(df.query('has_cancer')['test_result'] == 'Positive').mean()


# %%
# proportion of patients with cancer who test negative
(df.query('has_cancer')['test_result'] == 'Negative').mean()


# %%
# proportion of patients without cancer who test positive
(df.query('has_cancer == False')['test_result'] == 'Positive').mean()


# %%
# proportion of patients without cancer who test negative
(df.query('has_cancer == False')['test_result'] == 'Negative').mean()

# load dataset
import pandas as pd

df = pd.read_csv('cancer_test_data.csv')
df.head()

# What proportion of patients who tested positive has cancer?
df.query('test_result == "Positive"')['has_cancer'].mean()

# What proportion of patients who tested positive doesn't have cancer?
1 - df.query('test_result == "Positive"')['has_cancer'].mean()

# What proportion of patients who tested negative has cancer?
df.query('test_result == "Negative"')['has_cancer'].mean()

# What proportion of patients who tested negative doesn't have cancer?
1 - df.query('test_result == "Negative"')['has_cancer'].mean()


import numpy as np
import matplotlib.pyplot as plt
np.random.seed(42)

students = np.array([1,0,1,1,1,1,0,0,0,0,1,1,1,1,1,1,1,1,1,1,0])
sample_props = []
for _ in range(10000):
    sample = np.random.choice(students, 5, replace=True)
    sample_props.append(sample.mean())



p*(1-p) # The variance of the original data


p*(1-p)/5 # The variance of the sample mean of size 5


##Simulate your 20 draws
sample_props_20 = []
for _ in range(10000):
    sample = np.random.choice(students, 20, replace=True)
    sample_props_20.append(sample.mean())


##Compare your variance values as computed in 6 and 8, 
##but with your sample of 20 values


print(p*(1-p)/20) # The theoretical variance
print(np.array(sample_props_20).var()) # The simulated variance

plt.hist(sample_props, alpha=.5);
plt.hist(np.array(sample_props_20), alpha=.5);
```