CaduneTree by Wojciech Cierpucha
Version 0.6b

MIT license

Ogre Thread:	http://www.ogre3d.org/phpBB2/viewtopic.php?t=35250


-------------------------------------------------------------------

CaduneTree is a tree generator for OGRE (www.ogre3d.org). It is based on "Creation and rendering of realistic trees" by Jason Weber and Joseph Penn.
More to come later...

-------------------------------------------------------------------
Simple tutorial:

mParameters = new Parameters();
mTrunk = new Stem( mParameters );
mTrunk->grow( Quaternion::IDENTITY, Vector3::ZERO );
mTrunk->createGeometry( manualObject );
mTrunk->createLeaves( billboardSet );

Materials: "BarkNoLighting", "Leaves" and "Frond" are default ones.