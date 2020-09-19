## AABB physics component.

import glm/vec

import ../ec
import ../math/util
import ../physics/aabb

{.experimental: "implicitDeref".}

type
  AabbCollider* = ref object of RootObj
    ## General interface for colliders.

    resolveCollisionXImpl*: proc (collider: AabbCollider, subject: var Rectf,
                                  direction: XCheckDirection): bool
                                 {.nimcall.}
    resolveCollisionYImpl*: proc (collider: AabbCollider, subject: var Rectf,
                                  direction: YCheckDirection): bool
                                 {.nimcall.}
      ## Implementations for collision detection on the X/Y axes.

  AabbWall* = enum
    wallLeft
    wallRight
    wallTop
    wallBottom

  AabbPhysics* = object of RootComponent
    position*, velocity*, acceleration*: Vec2f
    size*: Vec2f
    elasticity*: float32                       ## how much velocity is
                                               ## lost or gained on collision
                                               ## with walls
    collidesWith: seq[AabbCollider]
    collidingWithWalls: array[AabbWall, bool]

proc hitbox*(physics: AabbPhysics): Rectf =
  ## Returns the physics body's hitbox.
  rectf(physics.position, physics.size)

proc collidingWithWall*(physics: AabbPhysics, wall: AabbWall): bool =
  ## Returns whether the physics body collides with the given wall.
  physics.collidingWithWalls[wall]

proc update(p: var AabbPhysics) =
  ## Ticks physics: updates position/velocity/acceleration, and resolves
  ## collisions with all colliders.

  # the easy part

  p.velocity += p.acceleration
  p.acceleration *= 0

  # collision resolution

  # just some variables for optimization
  let
    movingX = not p.velocity.x.closeTo(0.001)
    movingY = not p.velocity.y.closeTo(0.001)
  var hitbox: Rectf

  # of course we're not colliding with anything by default
  reset(p.collidingWithWalls)

  # X axis phase
  # to this day i'm not entirely sure why this axis separation is needed but eh
  # it works, so don't touch it.
  p.position.x += p.velocity.x
  hitbox = p.hitbox

  if movingX:
    let directionX = cdLeft.succ(ord(p.velocity.x > 0))
    for collider in p.collidesWith:
      let
        collides =
          collider.resolveCollisionXImpl(collider, hitbox, directionX)
        wall = wallLeft.succ(ord(directionX))
      p.position.x = hitbox.x
      if collides:
        p.velocity.x *= -p.elasticity
      p.collidingWithWalls[wall] = true

  # Y axis phase
  p.position.y += p.velocity.y
  hitbox = p.hitbox  # needs to be updated because the position was updated

  if movingY:
    let directionY = cdUp.succ(ord(p.velocity.y > 0))
    for collider in p.collidesWith:
      let
        collides =
          collider.resolveCollisionYImpl(collider, hitbox, directionY)
        wall = wallTop.succ(ord(directionY))
      p.position.y = hitbox.y
      if collides:
        p.velocity.y *= -p.elasticity
      p.collidingWithWalls[wall] = true

proc aabbPhysics*(position, size: Vec2f, colliders: varargs[AabbCollider],
                  velocity, acceleration = vec2f(0),
                  elasticity: float32 = 0): AabbPhysics =
  ## Constructs a new AabbPhysics component.

  result = AabbPhysics(position: position, velocity: velocity,
                       acceleration: acceleration,
                       elasticity: elasticity,
                       size: size,
                       collidesWith: @colliders)
  result.autoImplement()
