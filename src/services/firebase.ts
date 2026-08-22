import { initializeApp, getApps, getApp } from 'firebase/app';
import { getAuth, GoogleAuthProvider, signInWithPopup, signOut, onAuthStateChanged, User } from 'firebase/auth';
import { getFirestore, doc, getDoc, setDoc } from 'firebase/firestore';
import firebaseConfig from '../../firebase-applet-config.json';

const app = !getApps().length ? initializeApp(firebaseConfig) : getApp();
export const auth = getAuth(app);
export const db = firebaseConfig.firestoreDatabaseId 
  ? getFirestore(app, firebaseConfig.firestoreDatabaseId)
  : getFirestore(app);
export const googleProvider = new GoogleAuthProvider();

export interface CloudPortfolioData {
  fundTransactions?: any[];
  stockTransactions?: any[];
  fundFavorites?: any[];
  stockFavorites?: any[];
  fxFavorites?: any[];
  debts?: any[];
  notes?: any[];
  performance?: any[];
  performanceRecords?: any[];
  performanceTargetGrowth?: string;
  settings?: any;
  updatedAt?: string;
}

export const FirebaseService = {
  async signInWithGoogle(): Promise<User> {
    const result = await signInWithPopup(auth, googleProvider);
    const user = result.user;
    
    // Save/update profile in Firestore
    try {
      const userRef = doc(db, 'users', user.uid);
      await setDoc(userRef, {
        userId: user.uid,
        email: user.email || '',
        displayName: user.displayName || '',
        photoURL: user.photoURL || '',
        lastSyncedAt: new Date().toISOString(),
      }, { merge: true });
    } catch (e) {
      console.warn('Could not save user profile:', e);
    }
    
    return user;
  },

  async signOut(): Promise<void> {
    await signOut(auth);
  },

  onAuthStateChanged(callback: (user: User | null) => void) {
    return onAuthStateChanged(auth, callback);
  },

  async loadUserDataFromCloud(userId: string): Promise<CloudPortfolioData | null> {
    try {
      const dataRef = doc(db, 'users', userId, 'data', 'portfolio');
      const snap = await getDoc(dataRef);
      if (snap.exists()) {
        return snap.data() as CloudPortfolioData;
      }
      return null;
    } catch (err) {
      console.error('Failed to load user cloud data:', err);
      throw err;
    }
  },

  async saveUserDataToCloud(userId: string, data: CloudPortfolioData): Promise<void> {
    try {
      const dataRef = doc(db, 'users', userId, 'data', 'portfolio');
      await setDoc(dataRef, {
        ...data,
        updatedAt: new Date().toISOString(),
      }, { merge: true });
    } catch (err) {
      console.error('Failed to save user cloud data:', err);
      throw err;
    }
  }
};
