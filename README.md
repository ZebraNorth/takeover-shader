Takeover
========

This shader lets a material "take over" your avatar, expanding from the starting point until your whole avatar is covered.

Operation
=========

The shader transitions your textures by expanding a sphere from the Start Position until it encloses the avatar.  Anything outside the sphere will be the standard texture, anything inside the sphere will be the takeover texture.

Configuration
=============

The first section configures the primary texture:

- Colour: A plain colour.  This will tint the albedo texture.  Normally it should be white.
- Albedo (RGB): Your texture map.
- Smoothness: How shiny the surface should be.
- Metallic: How metallic the shine should be.

The second section configures the texture that will replace the primary texture:

- Colour: A plain colour.  This will tint the albedo texture.  Normally it should be white.
- Albedo (RGB): Your texture map.
- Smoothness: How shiny the surface should be.
- Metallic: How metallic the shine should be.

The third section configures how the transition should appear:

- Noise scale: A low number makes small blobs, a high number makes large blobs.  Try around 30.
- Start Position: The (x, y, z) position on your avatar from which the effect starts.
- Avatar Radius: The distance from the Start Position to the farthest point on your avatar.
- Transition Thickness: As the effect moves over your avatar it will fade in, and the size of that fade area is the transition thickness.  A value of zero will produce a sharp line betwen the old and new textures.  A higher value will give a blobby zone between the old and new textures.  Try around 0.3.
- Threshold: This is the mix between the primary and takeover textures.  Zero means all primary texture, one means all takeover texture.

Usage
=====

Create an animation that changes the Threshold parameter from zero at the start of the animation to one at the end of the animation.  See the VRC documentation on Avatars and Animation Controllers.

Thanks
======

This shader uses simplex noise implemented by Ian McEwan!  See noise.cginc for details.
