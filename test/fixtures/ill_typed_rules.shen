\* A deliberately ill-typed rules module. build.lua loads it under (tc +)
   and fails the build if the typechecker accepts it. *\

(define unii-fixture.view-ready?
  {number --> boolean}
  Count -> (+ Count 1))
