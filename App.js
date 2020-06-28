import { StatusBar } from 'expo-status-bar';
import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import {HexTile} from './src/components/HexTile'

export default function App() {
  return (
    <View style={styles.container}>
      <Text>Open up App.js to working your app!</Text>
      <HexTile />
      <StatusBar style="auto" />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#aff',
    alignItems: 'center',
    justifyContent: 'center',
  },
});
