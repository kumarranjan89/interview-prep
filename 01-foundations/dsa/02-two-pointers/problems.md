# Two Pointers — Problems

NeetCode 150 — Two Pointers section.  
Solve yourself first. Look only after 20 min.

---

## Problem 1 — Valid Palindrome

**Link:** https://leetcode.com/problems/valid-palindrome/

**Problem:**  
Given a string, return true if it is a palindrome — considering only alphanumeric characters, ignoring case.

```
Input:  "A man, a plan, a canal: Panama"
Output: true  → "amanaplanacanalpanama"

Input:  "race a car"
Output: false
```

**Pattern:** Opposite ends — move inward, skip non-alphanumeric.

**Approach:**
- Left pointer at 0, right at end
- Skip non-alphanumeric characters on both sides
- Compare characters (lowercase)
- Mismatch → false
- Pointers cross → true

**Dry Run:**
```
s = "A man, a plan, a canal: Panama"

L=0  'A' alphanumeric ✅
R=29 'a' alphanumeric ✅
'a' === 'a' → move both → L++, R--

L=1  ' ' skip → L++
L=2  'm' ✅
R=28 'm' ✅ (Panam'a' already matched)
'm' === 'm' → L++, R--

... continues until L >= R → return true ✅
```

**Solution:**
```js
function isPalindrome(s) {
  let left = 0;
  let right = s.length - 1;

  const isAlphanumeric = (c) => /[a-z0-9]/.test(c.toLowerCase());

  while (left < right) {
    while (left < right && !isAlphanumeric(s[left])) left++;
    while (left < right && !isAlphanumeric(s[right])) right--;

    if (s[left].toLowerCase() !== s[right].toLowerCase()) return false;

    left++;
    right--;
  }

  return true;
}
```

**Complexity:**
| | |
|--|--|
| Time | O(n) |
| Space | O(1) |

**Edge Cases:**
- Empty string → true
- Single character → true
- All special characters → true (no alphanumeric to compare)
- Mixed case → handle with toLowerCase()

---

## Problem 2 — Two Sum II (Input Array is Sorted)

**Link:** https://leetcode.com/problems/two-sum-ii-input-array-is-sorted/

**Problem:**  
Given a **sorted** array, find two numbers that add up to target.  
Return 1-indexed positions. Must use O(1) extra space.

```
Input:  numbers = [2,7,11,15], target = 9
Output: [1,2]  → numbers[0] + numbers[1] = 2 + 7 = 9
```

**Pattern:** Opposite ends — sorted array, adjust based on sum.

**Approach:**
- Left at 0, right at end
- sum < target → left++ (need bigger)
- sum > target → right-- (need smaller)
- sum === target → return

**Dry Run:**
```
numbers = [2, 7, 11, 15], target = 9
L=0, R=3

2+15=17 > 9 → R--
2+11=13 > 9 → R--
2+7=9 === 9 → return [1,2] ✅
```

**Solution:**
```js
function twoSum(numbers, target) {
  let left = 0;
  let right = numbers.length - 1;

  while (left < right) {
    const sum = numbers[left] + numbers[right];
    if (sum === target) return [left + 1, right + 1];
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

**Edge Cases:**
- Exactly one solution guaranteed
- Negative numbers → works fine (sorted)
- Duplicate values → works fine

---

## Problem 3 — 3Sum

**Link:** https://leetcode.com/problems/3sum/

**Problem:**  
Find all unique triplets that sum to zero.

```
Input:  [-1,0,1,2,-1,-4]
Output: [[-1,-1,2],[-1,0,1]]
```

**Pattern:** Sort + fix one element + two pointers on rest.

**Approach:**
- Sort the array
- Loop i from 0 to n-2 (fix first element)
- Skip duplicates for i
- Two pointers: left = i+1, right = end
- sum < 0 → left++
- sum > 0 → right--
- sum === 0 → add to result, skip duplicates, move both pointers

**Dry Run:**
```
nums = [-4,-1,-1,0,1,2]  (sorted)

i=0, nums[i]=-4
  L=1(-1), R=5(2) → -4-1+2=-3 < 0 → L++
  L=2(-1), R=5(2) → -4-1+2=-3 < 0 → L++
  L=3(0),  R=5(2) → -4+0+2=-2 < 0 → L++
  L=4(1),  R=5(2) → -4+1+2=-1 < 0 → L++
  L=5 → L not < R → done

i=1, nums[i]=-1
  L=2(-1), R=5(2) → -1-1+2=0 → add [-1,-1,2] ✅
  skip duplicates → L++, R--
  L=3(0), R=4(1) → -1+0+1=0 → add [-1,0,1] ✅
  skip → L++, R--
  L=4 → L not < R → done

i=2, nums[i]=-1 → same as i=1 → skip (duplicate)
i=3, nums[i]=0
  L=4(1), R=5(2) → 0+1+2=3 > 0 → R--
  L not < R → done

Result: [[-1,-1,2],[-1,0,1]] ✅
```

**Solution:**
```js
function threeSum(nums) {
  nums.sort((a, b) => a - b);
  const result = [];

  for (let i = 0; i < nums.length - 2; i++) {
    // skip duplicates for i
    if (i > 0 && nums[i] === nums[i - 1]) continue;

    let left = i + 1;
    let right = nums.length - 1;

    while (left < right) {
      const sum = nums[i] + nums[left] + nums[right];

      if (sum === 0) {
        result.push([nums[i], nums[left], nums[right]]);
        // skip duplicates for left and right
        while (left < right && nums[left] === nums[left + 1]) left++;
        while (left < right && nums[right] === nums[right - 1]) right--;
        left++;
        right--;
      } else if (sum < 0) {
        left++;
      } else {
        right--;
      }
    }
  }

  return result;
}
```

**Complexity:**
| | |
|--|--|
| Time | O(n²) — sort O(n log n) + loop O(n²) |
| Space | O(1) — ignoring output |

**Edge Cases:**
- All zeros → [[0,0,0]]
- Less than 3 elements → []
- All positives → []
- Duplicates → handle with skip logic

---

## Problem 4 — Container With Most Water

**Link:** https://leetcode.com/problems/container-with-most-water/

**Problem:**  
Given heights array, find two lines that form container with most water.

```
Input:  [1,8,6,2,5,4,8,3,7]
Output: 49
→ lines at index 1 (height 8) and index 8 (height 7)
→ width = 7, height = min(8,7) = 7 → area = 49
```

**Pattern:** Opposite ends — always move the shorter line inward.

**Approach:**
- Left at 0, right at end
- area = min(height[L], height[R]) * (R - L)
- Move the pointer with shorter height (moving taller one can only decrease area)
- Track max area

**Dry Run:**
```
heights = [1,8,6,2,5,4,8,3,7]
L=0, R=8

area = min(1,7) * 8 = 8, max=8
height[L]=1 < height[R]=7 → L++

L=1, R=8
area = min(8,7) * 7 = 49, max=49
height[L]=8 > height[R]=7 → R--

L=1, R=7
area = min(8,3) * 6 = 18, max=49
height[R]=3 < height[L]=8 → R--

... continues, max stays 49

return 49 ✅
```

**Solution:**
```js
function maxArea(height) {
  let left = 0;
  let right = height.length - 1;
  let max = 0;

  while (left < right) {
    const area = Math.min(height[left], height[right]) * (right - left);
    max = Math.max(max, area);

    if (height[left] < height[right]) left++;
    else right--;
  }

  return max;
}
```

**Complexity:**
| | |
|--|--|
| Time | O(n) |
| Space | O(1) |

**Edge Cases:**
- Two elements → only one container possible
- All same height → area = height * (n-1)
- Decreasing heights → still works

---

## Problem 5 — Trapping Rain Water

**Link:** https://leetcode.com/problems/trapping-rain-water/

**Problem:**  
Given heights, compute how much rain water can be trapped.

```
Input:  [0,1,0,2,1,0,1,3,2,1,2,1]
Output: 6
```

**Pattern:** Two pointers — track max from left and right.

**Approach:**
- Water at any position = min(maxLeft, maxRight) - height[i]
- Use two pointers: process side with smaller max first
- If maxLeft < maxRight → water at left = maxLeft - height[left] → left++
- Else → water at right = maxRight - height[right] → right--

**Dry Run:**
```
heights = [0,1,0,2,1,0,1,3,2,1,2,1]
L=0, R=11, maxL=0, maxR=0, water=0

L=0: h=0, maxL=0 → water += max(0, 0-0)=0, L++
L=1: h=1, maxL=1 → water += 0, L++
L=2: h=0, maxL=1 → water += 1-0=1, L++  (water=1)
R=11: h=1, maxR=1, maxL=1 equal → process right
R=11: h=1, maxR=1 → water += 0, R--
R=10: h=2, maxR=2 → water += 0, R--
...continues → total = 6 ✅
```

**Solution:**
```js
function trap(height) {
  let left = 0;
  let right = height.length - 1;
  let maxLeft = 0;
  let maxRight = 0;
  let water = 0;

  while (left < right) {
    if (maxLeft <= maxRight) {
      maxLeft = Math.max(maxLeft, height[left]);
      water += maxLeft - height[left];
      left++;
    } else {
      maxRight = Math.max(maxRight, height[right]);
      water += maxRight - height[right];
      right--;
    }
  }

  return water;
}
```

**Complexity:**
| | |
|--|--|
| Time | O(n) |
| Space | O(1) |

**Edge Cases:**
- Flat array → 0
- Strictly increasing → 0
- Single valley → works

---

## Summary

| # | Problem | Pattern | Time | Space |
|---|---------|---------|------|-------|
| 1 | Valid Palindrome | Opposite ends | O(n) | O(1) |
| 2 | Two Sum II | Opposite ends | O(n) | O(1) |
| 3 | 3Sum | Sort + Two Pointers | O(n²) | O(1) |
| 4 | Container With Most Water | Opposite ends | O(n) | O(1) |
| 5 | Trapping Rain Water | Opposite ends + max tracking | O(n) | O(1) |