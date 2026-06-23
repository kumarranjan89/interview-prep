# Two Pointers — Concepts

---

## What is Two Pointers?

Use **two index variables** to traverse an array or string — instead of nested loops.  
Reduces O(n²) to O(n).

```
Array:  [1, 2, 3, 4, 5]
         ↑              ↑
        left           right

Move them toward each other (or same direction) based on condition.
```

---

## Two Types

### Type 1 — Opposite Ends (most common)

Start left at 0, right at end. Move inward.

```
[1, 2, 3, 4, 5]
 L              R   → check condition → move L or R
```

**Use when:**
- Sorted array
- Finding pairs (two sum, target sum)
- Palindrome check
- Container with most water

---

### Type 2 — Same Direction (slow & fast)

Both start at 0 or 1. One moves faster.

```
[1, 2, 2, 3, 4]
 S
    F           → fast explores, slow marks valid position
```

**Use when:**
- Remove duplicates
- Move zeros to end
- Partition array

---

## Core Pattern — Opposite Ends

```js
let left = 0;
let right = arr.length - 1;

while (left < right) {
  if (/* condition met */) {
    return result;
  } else if (/* need bigger value */) {
    left++;
  } else {
    right--;
  }
}
```

---

## Core Pattern — Same Direction

```js
let slow = 0;

for (let fast = 0; fast < arr.length; fast++) {
  if (/* valid element */) {
    arr[slow] = arr[fast];
    slow++;
  }
}

return slow; // slow = count of valid elements
```

---

## Classic Example — Two Sum II (Sorted Array)

```
Input:  [1, 3, 5, 7, 9], target = 8
Output: [1, 3]  → indices (1-indexed)
```

**Why two pointers work here:** Array is sorted.  
- Sum too small → move left pointer right (increase sum)  
- Sum too big → move right pointer left (decrease sum)

**Dry Run:**
```
arr = [1, 3, 5, 7, 9], target = 8
L=0, R=4

Step 1: arr[0]+arr[4] = 1+9 = 10 > 8 → R--
Step 2: arr[0]+arr[3] = 1+7 = 8 = target → return [1,4] ✅
```

**Solution:**
```js
function twoSumII(numbers, target) {
  let left = 0;
  let right = numbers.length - 1;

  while (left < right) {
    const sum = numbers[left] + numbers[right];
    if (sum === target) return [left + 1, right + 1]; // 1-indexed
    else if (sum < target) left++;
    else right--;
  }
}
```

**Complexity:**
| | |
|--|--|
| Time | O(n) |
| Space | O(1) |

---

## Recognize This Pattern When

- Array is **sorted** (opposite ends pointer)
- "Find pair that satisfies condition"
- "Check if palindrome"
- Brute force needs nested loop O(n²) — two pointer makes it O(n)
- "Remove/move elements in-place"

---

## Key Insight

Two pointers eliminates the inner loop.  
Instead of checking every pair (n²), you make a smart decision at each step which pointer to move — reducing to O(n).

---

## Complexity Summary

| Approach | Time | Space |
|----------|------|-------|
| Brute force (nested loop) | O(n²) | O(1) |
| Two pointers | O(n) | O(1) |

Space is O(1) — no extra data structure needed. This is the advantage over hash map approach.