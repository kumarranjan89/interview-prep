# Arrays & Hashing — Problems

NeetCode 150 — Arrays & Hashing section.  
Solve yourself first. Look only after 20 min.

---

## Problem 1 — Contains Duplicate

**Link:** https://leetcode.com/problems/contains-duplicate/

**Problem:**  
Given an integer array `nums`, return `true` if any value appears at least twice, else `false`.

```
Input:  [1, 2, 3, 1]
Output: true

Input:  [1, 2, 3, 4]
Output: false
```

**Pattern:** Hash Set — store seen elements, check if already seen.

**Approach:**
- Loop through array
- If current element already in set → duplicate found → return true
- Else add to set
- End of loop → no duplicate → return false

**Dry Run:**
```
nums = [1, 2, 3, 1]
seen = {}

i=0 → 1 → not in seen → seen = {1}
i=1 → 2 → not in seen → seen = {1,2}
i=2 → 3 → not in seen → seen = {1,2,3}
i=3 → 1 → IN seen → return true ✅
```

**Solution:**
```js
function containsDuplicate(nums) {
  const seen = new Set();
  for (const num of nums) {
    if (seen.has(num)) return true;
    seen.add(num);
  }
  return false;
}
```

**Complexity:**
| | |
|--|--|
| Time | O(n) |
| Space | O(n) |

**Edge Cases:**
- Single element → false
- All same elements → true
- Empty array → false

---

## Problem 2 — Valid Anagram

**Link:** https://leetcode.com/problems/valid-anagram/

**Problem:**  
Given two strings `s` and `t`, return `true` if `t` is an anagram of `s`.  
Anagram = same characters, same frequency, different order.

```
Input:  s = "anagram", t = "nagaram"
Output: true

Input:  s = "rat", t = "car"
Output: false
```

**Pattern:** Hash Map — count character frequency.

**Approach:**
- If lengths differ → not anagram → return false
- Count frequency of each character in `s`
- For each character in `t` → decrement count
- If any count goes negative → extra character → return false

**Dry Run:**
```
s = "rat", t = "tar"

Step 1: lengths equal ✅

Step 2: count from s
count = { r:1, a:1, t:1 }

Step 3: decrement from t
t[0] = 't' → count = { r:1, a:1, t:0 }
t[1] = 'a' → count = { r:1, a:0, t:0 }
t[2] = 'r' → count = { r:0, a:0, t:0 }

All zeros → return true ✅
```

**Solution:**
```js
function isAnagram(s, t) {
  if (s.length !== t.length) return false;

  const count = new Map();

  for (const char of s) {
    count.set(char, (count.get(char) || 0) + 1);
  }

  for (const char of t) {
    if (!count.has(char) || count.get(char) === 0) return false;
    count.set(char, count.get(char) - 1);
  }

  return true;
}
```

**Complexity:**
| | |
|--|--|
| Time | O(n) |
| Space | O(1) — max 26 chars |

**Edge Cases:**
- Different lengths → false immediately
- Same string → true
- Empty strings → true

---

## Problem 3 — Two Sum

**Link:** https://leetcode.com/problems/two-sum/

**Problem:**  
Given array `nums` and integer `target`, return indices of two numbers that add up to target.  
Exactly one solution exists.

```
Input:  nums = [2,7,11,15], target = 9
Output: [0,1]  → nums[0] + nums[1] = 2 + 7 = 9

Input:  nums = [3,4,5,3], target = 6
Output: [0,3]
```

**Pattern:** Hash Map — store value → index, look up complement.

**Approach:**
- For each number, calculate complement = target - num
- Check if complement already seen in map
- If yes → return [map[complement], current index]
- If no → store current number with its index

**Dry Run:**
```
nums = [2, 7, 11, 15], target = 9
map = {}

i=0 → num=2, complement=9-2=7 → not in map → map={2:0}
i=1 → num=7, complement=9-7=2 → IN map at index 0 → return [0,1] ✅
```

**Solution:**
```js
function twoSum(nums, target) {
  const map = new Map(); // value → index

  for (let i = 0; i < nums.length; i++) {
    const complement = target - nums[i];
    if (map.has(complement)) {
      return [map.get(complement), i];
    }
    map.set(nums[i], i);
  }
}
```

**Complexity:**
| | |
|--|--|
| Time | O(n) |
| Space | O(n) |

**Edge Cases:**
- Same element used twice → won't happen (map stores index, check complement first)
- Negative numbers → works fine
- Target = 0 → works fine

---

## Problem 4 — Group Anagrams

**Link:** https://leetcode.com/problems/group-anagrams/

**Problem:**  
Given array of strings, group anagrams together.

```
Input:  ["eat","tea","tan","ate","nat","bat"]
Output: [["eat","tea","ate"], ["tan","nat"], ["bat"]]
```

**Pattern:** Hash Map — sorted word as key, group words with same key.

**Approach:**
- For each word, sort its characters → this becomes the key
- All anagrams will have same sorted key
- Push word into map[key]
- Return all values

**Dry Run:**
```
"eat" → sorted = "aet" → map = { aet: ["eat"] }
"tea" → sorted = "aet" → map = { aet: ["eat","tea"] }
"tan" → sorted = "ant" → map = { aet: ["eat","tea"], ant: ["tan"] }
"ate" → sorted = "aet" → map = { aet: ["eat","tea","ate"], ant: ["tan"] }
"nat" → sorted = "ant" → map = { aet: ["eat","tea","ate"], ant: ["tan","nat"] }
"bat" → sorted = "abt" → map = { aet: [...], ant: [...], abt: ["bat"] }

Result: [["eat","tea","ate"], ["tan","nat"], ["bat"]] ✅
```

**Solution:**
```js
function groupAnagrams(strs) {
  const map = new Map();

  for (const word of strs) {
    const key = word.split('').sort().join('');
    if (!map.has(key)) map.set(key, []);
    map.get(key).push(word);
  }

  return Array.from(map.values());
}
```

**Complexity:**
| | |
|--|--|
| Time | O(n * k log k) — k = max word length |
| Space | O(n) |

**Edge Cases:**
- Single character strings → works
- All same strings → one group
- Empty string → sorted = "" → valid key

---

## Problem 5 — Top K Frequent Elements

**Link:** https://leetcode.com/problems/top-k-frequent-elements/

**Problem:**  
Given array `nums` and integer `k`, return the `k` most frequent elements.

```
Input:  nums = [1,1,1,2,2,3], k = 2
Output: [1,2]

Input:  nums = [1], k = 1
Output: [1]
```

**Pattern:** Hash Map + Bucket Sort.

**Approach:**
- Count frequency of each number using map
- Bucket sort: index = frequency, value = list of numbers with that frequency
- Iterate buckets from high to low, collect until k elements found

**Dry Run:**
```
nums = [1,1,1,2,2,3], k = 2

Step 1: count = { 1:3, 2:2, 3:1 }

Step 2: buckets (index = frequency)
bucket[1] = [3]
bucket[2] = [2]
bucket[3] = [1]

Step 3: iterate from end
bucket[3] → [1] → result = [1]
bucket[2] → [2] → result = [1,2] → size = k → stop ✅
```

**Solution:**
```js
function topKFrequent(nums, k) {
  const count = new Map();
  for (const num of nums) {
    count.set(num, (count.get(num) || 0) + 1);
  }

  // bucket index = frequency
  const bucket = Array.from({ length: nums.length + 1 }, () => []);
  for (const [num, freq] of count) {
    bucket[freq].push(num);
  }

  const result = [];
  for (let i = bucket.length - 1; i >= 0; i--) {
    for (const num of bucket[i]) {
      result.push(num);
      if (result.length === k) return result;
    }
  }
}
```

**Complexity:**
| | |
|--|--|
| Time | O(n) |
| Space | O(n) |

**Edge Cases:**
- k = array length → return all
- All elements same frequency → any k valid

---

## Problem 6 — Product of Array Except Self

**Link:** https://leetcode.com/problems/product-of-array-except-self/

**Problem:**  
Return array where each element is product of all other elements.  
**No division allowed. Must be O(n).**

```
Input:  [1,2,3,4]
Output: [24,12,8,6]
→ output[0] = 2*3*4 = 24
→ output[1] = 1*3*4 = 12
```

**Pattern:** Prefix and Suffix products.

**Approach:**
- Pass 1 (left to right): for each index, store product of all elements to its LEFT
- Pass 2 (right to left): multiply each index with product of all elements to its RIGHT

**Dry Run:**
```
nums = [1, 2, 3, 4]

Prefix (product of everything LEFT):
output = [1, 1, 2, 6]
→ output[0] = 1 (nothing to left)
→ output[1] = 1
→ output[2] = 1*2 = 2
→ output[3] = 1*2*3 = 6

Suffix (multiply product of everything RIGHT):
suffix = 1
i=3 → output[3] = 6*1 = 6,  suffix = 1*4 = 4
i=2 → output[2] = 2*4 = 8,  suffix = 4*3 = 12
i=1 → output[1] = 1*12 = 12, suffix = 12*2 = 24
i=0 → output[0] = 1*24 = 24, suffix = 24*1 = 24

Result: [24, 12, 8, 6] ✅
```

**Solution:**
```js
function productExceptSelf(nums) {
  const output = new Array(nums.length).fill(1);

  // prefix pass
  let prefix = 1;
  for (let i = 0; i < nums.length; i++) {
    output[i] = prefix;
    prefix *= nums[i];
  }

  // suffix pass
  let suffix = 1;
  for (let i = nums.length - 1; i >= 0; i--) {
    output[i] *= suffix;
    suffix *= nums[i];
  }

  return output;
}
```

**Complexity:**
| | |
|--|--|
| Time | O(n) |
| Space | O(1) — output array not counted |

**Edge Cases:**
- Contains zero → product of others will be 0 except position of zero
- Two zeros → all zeros
- Negative numbers → works fine

---

## Problem 7 — Valid Sudoku

**Link:** https://leetcode.com/problems/valid-sudoku/

**Problem:**  
Determine if a 9x9 Sudoku board is valid.  
Each row, column, and 3x3 box must have digits 1-9 with no repeats.

```
Valid board → true
Any duplicate in row/col/box → false
```

**Pattern:** Hash Set for each row, column, and box.

**Approach:**
- Use 3 sets: rows[9], cols[9], boxes[9]
- For each cell with a number:
  - Check if number exists in its row set → invalid
  - Check if number exists in its col set → invalid
  - Check if number exists in its box set → invalid
  - Add to all three sets
- Box index = Math.floor(r/3) * 3 + Math.floor(c/3)

**Dry Run:**
```
Cell at row=0, col=0, value="5"
box index = floor(0/3)*3 + floor(0/3) = 0

Check rows[0] → not has "5" ✅
Check cols[0] → not has "5" ✅  
Check boxes[0] → not has "5" ✅
Add "5" to rows[0], cols[0], boxes[0]
```

**Solution:**
```js
function isValidSudoku(board) {
  const rows = Array.from({ length: 9 }, () => new Set());
  const cols = Array.from({ length: 9 }, () => new Set());
  const boxes = Array.from({ length: 9 }, () => new Set());

  for (let r = 0; r < 9; r++) {
    for (let c = 0; c < 9; c++) {
      const val = board[r][c];
      if (val === '.') continue;

      const boxIndex = Math.floor(r / 3) * 3 + Math.floor(c / 3);

      if (rows[r].has(val) || cols[c].has(val) || boxes[boxIndex].has(val)) {
        return false;
      }

      rows[r].add(val);
      cols[c].add(val);
      boxes[boxIndex].add(val);
    }
  }

  return true;
}
```

**Complexity:**
| | |
|--|--|
| Time | O(1) — fixed 9x9 board |
| Space | O(1) — fixed size sets |

**Edge Cases:**
- Empty cells (`.`) → skip
- Already filled valid board → true
- Same number in same box → false

---

## Problem 8 — Longest Consecutive Sequence

**Link:** https://leetcode.com/problems/longest-consecutive-sequence/

**Problem:**  
Given unsorted array, find length of longest consecutive sequence.  
Must be O(n).

```
Input:  [100,4,200,1,3,2]
Output: 4  → sequence [1,2,3,4]

Input:  [0,3,7,2,5,8,4,6,0,1]
Output: 9
```

**Pattern:** Hash Set — find sequence start, expand.

**Approach:**
- Add all numbers to a Set
- For each number, check if it's a sequence START (num-1 not in set)
- If start → count consecutive numbers forward
- Track max length

**Dry Run:**
```
nums = [100,4,200,1,3,2]
set = {100,4,200,1,3,2}

num=100 → 99 not in set → start! → 100,101? no → length=1
num=4   → 3 in set → not start, skip
num=200 → 199 not in set → start! → 200,201? no → length=1
num=1   → 0 not in set → start! → 1,2✅ 3✅ 4✅ 5?no → length=4
num=3   → 2 in set → not start, skip
num=2   → 1 in set → not start, skip

max = 4 ✅
```

**Solution:**
```js
function longestConsecutive(nums) {
  const set = new Set(nums);
  let maxLen = 0;

  for (const num of set) {
    // only start counting from sequence start
    if (!set.has(num - 1)) {
      let current = num;
      let length = 1;

      while (set.has(current + 1)) {
        current++;
        length++;
      }

      maxLen = Math.max(maxLen, length);
    }
  }

  return maxLen;
}
```

**Complexity:**
| | |
|--|--|
| Time | O(n) |
| Space | O(n) |

**Edge Cases:**
- Empty array → 0
- All same numbers → 1
- Already sorted → works fine
- Duplicates → set handles it

---

## Summary

| # | Problem | Pattern | Time | Space |
|---|---------|---------|------|-------|
| 1 | Contains Duplicate | Hash Set | O(n) | O(n) |
| 2 | Valid Anagram | Hash Map | O(n) | O(1) |
| 3 | Two Sum | Hash Map | O(n) | O(n) |
| 4 | Group Anagrams | Hash Map + Sort | O(n k log k) | O(n) |
| 5 | Top K Frequent | Hash Map + Bucket | O(n) | O(n) |
| 6 | Product Except Self | Prefix + Suffix | O(n) | O(1) |
| 7 | Valid Sudoku | Hash Set | O(1) | O(1) |
| 8 | Longest Consecutive | Hash Set | O(n) | O(n) |