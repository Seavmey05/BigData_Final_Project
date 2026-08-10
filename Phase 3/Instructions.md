**Phase 3 is basically the "math and statistics" part of your project.** You take the clean data from Phase 2 and use **NumPy** to calculate useful results.

### Phase 3 has only 4 main tasks:

#### 1. RFM Customer Segmentation

Figure out which customers are:

* 🟢 **Best customers** — buy often and spend a lot
* 🟡 **Good customers**
* 🟠 **Occasional customers**
* 🔴 **Customers at risk**

You calculate:

* **R = Recency** → How recently they purchased
* **F = Frequency** → How often they purchased
* **M = Monetary** → How much they spent

Then give customers scores and put them into segments.

---

#### 2. Product Recommendations

Use **cosine similarity** to find products that are similar.

For example:

> Customer A bought Nike shoes and Adidas shoes.

The system might recommend:

> "You may also like Puma shoes."

You need to calculate the similarity **using NumPy**, rather than using a ready-made machine-learning function.

---

#### 3. Regression / Prediction

Use your historical data to make a simple prediction.

For example:

> Based on previous monthly revenue, what will revenue probably be next month?

You use the **Normal Equation** with NumPy to create the regression model.

Then calculate **R²** to see how well the model fits the data.

---

#### 4. Monte Carlo Simulation

This sounds complicated, but the idea is simple:

> "If demand changes randomly, how likely are we to run out of stock?"

For example:

```text
Product A → 35% chance of stockout
Product B → 12% chance
Product C → 48% chance
```

You run the simulation **at least 5,000 times** to estimate the risk.

---

### So, in one sentence:

**Phase 3 = Use NumPy to do 4 mathematical analyses:**

```text
CLEAN DATA
    ↓
┌─────────────────────┐
│ 1. RFM              │ → Customer segments
│ 2. Similarity       │ → Product recommendations
│ 3. Regression       │ → Revenue prediction
│ 4. Monte Carlo      │ → Stockout risk
└─────────────────────┘
```

And importantly, your professor wants you to **actually calculate these using NumPy**, rather than simply calling a ready-made function.

**You can do all of Phase 3 inside your Jupyter Notebook.**
