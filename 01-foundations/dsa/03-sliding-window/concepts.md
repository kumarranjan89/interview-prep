# Sliding Window — Concepts

---

## What is Sliding Window?

A **window** is a subarray/substring between two indices.  
Instead of recalculating from scratch, **slide** the window — add one element from right, remove one from left.

```
Array:  [1, 3, 5, 2, 8, 4]
         [----]              window of size 3
            [----]           slide right
               [----]        slide right again
```

Reduces O(n²) or O(n³) to O(n).

---

## Two Types

### Type 1 — Fixed Size Window

Window size is given (k).  
Slide one step at a time — add right, remove left.

```
k=3, arr=[1,3,5,2,8,4]

Window 1: [1,3,5]  sum=9
Window 2: [3,5,2]  sum=10  → added 2, removed 1
Window 3: [5,2,8]  sum=15  → added 8, removed 3
Window 4: [2,8,4]  sum=14  → added 4, removed 5
```

**Use when:** "max/min/avg of subarray of size k"

---

### Type 2 — Variable Size Window

Window grows and shrinks based on condition.  
Left pointer moves when condition is violated.

```
Find longest subarray with sum <= target

[2, 1, 5, 2, 3, 2], target=7

Expand right until sum > target
Shrink left until sum <= target again
```

**Use when:** "longest/shortest subarray/substring that satisfies condition"

---

## Core Pattern — Fixed Window

```js
let windowSum = 0;

// build first window
for (let i = 0; i < k; i++) {
  windowSum += arr[i];
}

let max = windowSum;

// slide
for (let i = k; i < arr.length; i++) {
  windowSum += arr[i];       // add new right element
  windowSum -= arr[i - k];   // remove old left element
  max = Math.max(max, windowSum);
}
```

---

## Core Pattern — Variable Window

```js
let left = 0;
let windowState = 0; // sum, count, map etc.

for (let right = 0; right < arr.length; right++) {
  // expand window — add arr[right]
  windowState += arr[right];

  // shrink window — condition violated
  while (/* condition violated */) {
    windowState -= arr[left];
    left++;
  }

  // window is valid — update result
  result = Math.max(result, right - left + 1);
}
```

---

## Classic Example — Max Sum Subarray of Size K

```
Input:  arr = [2,1,5,1,3,2], k = 3
Output: 9  → subarray [5,1,3]
```

**Dry Run:**
```
First window: [2,1,5] sum=8, max=8

Slide:
add 1, remove 2 → [1,5,1] sum=7, max=8
add 3, remove 1 → [5,1,3] sum=9, max=9
add 2, remove 5 → [1,3,2] sum=6, max=9

return 9 ✅
```

**Solution:**
```js
function maxSumSubarray(arr, k) {
  let sum = 0;
  for (let i = 0; i < k; i++) sum += arr[i];

  let max = sum;
  for (let i = k; i < arr.length; i++) {
    sum += arr[i] - arr[i - k];
    max = Math.max(max, sum);
  }
  return max;
}
```

**Complexity:**
| | |
|--|--|
| Time | O(n) |
| Space | O(1) |

---

## Recognize This Pattern When

- "Subarray" or "substring" in problem
- "Contiguous elements"
- "Maximum/minimum/longest/shortest" with a constraint
- Brute force uses nested loop — sliding window makes it O(n)
- Elements are added/removed from one end at a time

---

## Key Difference — Two Pointers vs Sliding Window

| | Two Pointers | Sliding Window |
|--|-------------|----------------|
| Data | Usually sorted | Usually unsorted |
| Movement | Both can move independently | Right always moves forward |
| Use case | Pairs, palindrome | Subarrays, substrings |
| Space | O(1) | O(1) or O(k) |

---

## Complexity Summary

| Approach | Time | Space |
|----------|------|-------|
| Brute force (nested) | O(n²) | O(1) |
| Sliding window | O(n) | O(1) or O(k) |