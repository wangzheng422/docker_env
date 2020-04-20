# numpy

```python

# We import NumPy into Python
import numpy as np

np.array([[1,2,3],[4,5,6],[7,8,9], [10,11,12]])
# We create a rank 1 ndarray of floats but set the dtype to int64
x = np.array([1.5, 2.2, 3.7, 4.0, 5.9], dtype = np.int64)
# We create a 3 x 4 ndarray full of zeros. 
X = np.zeros((3,4))
# We create a 3 x 2 ndarray full of ones. 
X = np.ones((3,2))
# We create a 2 x 3 ndarray full of fives. 
X = np.full((2,3), 5) 
# We create a 5 x 5 Identity matrix. 
X = np.eye(5)
# Create a 4 x 4 diagonal matrix that contains the numbers 10,20,30, and 50
# on its main diagonal
X = np.diag([10,20,30,50])
# We create a rank 1 ndarray that has sequential integers from 0 to 9
x = np.arange(10)
# We create a rank 1 ndarray that has sequential integers from 4 to 9. 
x = np.arange(4,10)
# We create a rank 1 ndarray that has evenly spaced integers from 1 to 13 in steps of 3.
x = np.arange(1,14,3)
# We create a rank 1 ndarray that has 10 integers evenly spaced between 0 and 25.
x = np.linspace(0,25,10)
# We create a rank 1 ndarray that has 10 integers evenly spaced between 0 and 25,
# with 25 excluded.
x = np.linspace(0,25,10, endpoint = False)
# We create a rank 1 ndarray with 10 integers evenly spaced between 0 and 50,
# with 50 excluded. We then reshape it to a 5 x 2 ndarray
X = np.linspace(0,50,10, endpoint=False).reshape(5,2)
# We create a 3 x 2 ndarray with random integers in the half-open interval [4, 15).
X = np.random.randint(4,15,size=(3,2))
# We create a 1000 x 1000 ndarray of random floats drawn from normal (Gaussian) distribution
# with a mean of zero and a standard deviation of 0.1.
X = np.random.normal(0, 0.1, size=(1000,1000))
# We delete the first row of y
w = np.delete(Y, 0, axis=0)
# We delete the first and last column of y
v = np.delete(Y, [0,2], axis=1)
# We append the integer 7 and 8 to x
x = np.append(x, [7,8])
# We append a new row containing 7,8,9 to y
v = np.append(Y, [[7,8,9]], axis=0)

# We append a new column containing 9 and 10 to y
q = np.append(Y,[[9],[10]], axis=1)
# We insert the integer 3 and 4 between 2 and 5 in x. 
x = np.insert(x,2,[3,4])

# We insert a row between the first and last row of y
w = np.insert(Y,1,[4,5,6],axis=0)

# We insert a column full of 5s between the first and second column of y
v = np.insert(Y,1,5, axis=1)

# We stack x on top of Y
z = np.vstack((x,Y))

# We stack x on the right of Y. We need to reshape x in order to stack it on the right of Y. 
w = np.hstack((Y,x.reshape(2,1)))

```